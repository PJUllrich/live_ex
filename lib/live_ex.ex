defmodule LiveEx do
  @moduledoc """
  Documentation for LiveEx.
  """

  @type socket :: Phoenix.LiveView.Socket.t()

  @callback init(socket) :: socket

  defmacro __using__(opts) do
    pubsub_name = Keyword.get(opts, :pubsub_name, :live_ex_pubsub)
    log_output = Keyword.get(opts, :log, true)

    quote do
      require Logger

      import Phoenix.LiveView, only: [assign: 3, assign_new: 3]

      @type socket :: Phoenix.LiveView.Socket.t()

      @behaviour LiveEx

      @default_store_pid_key :store_pid

      @doc """
      Configures the socket with an initial setup.

      The `pid` of the parent process is stored in the `socket.assigns` so that
      Child processes can dispatch Actions on the parents's Store.
      """
      @spec init(map, socket) :: socket
      def init(state, socket, store_pid_key \\ @default_store_pid_key) when is_map(state) do
        store_pid = Map.get(state, store_pid_key, self())

        socket =
          state
          |> Map.put_new(:live_ex_store_topic, store_topic(store_pid))
          |> Map.put_new(store_pid_key, self())
          |> Enum.reduce(socket, fn {key, val}, socket ->
            assign_new(socket, key, fn -> val end)
          end)

        if Phoenix.LiveView.connected?(socket) do
          :ok = subscribe(socket.assigns.live_ex_store_topic)
        end

        socket
      end

      def subscribe(topic) do
        Phoenix.PubSub.subscribe(unquote(pubsub_name), topic)
      end

      @doc """
      Dispatch an Action with a `type` and an optional payload.
      """
      @spec dispatch(pid, String.t(), any, socket) :: :ok | {:error, term}
      def dispatch(store_pid, type, payload \\ nil, socket)
          when is_binary(type) do
        if is_nil(socket.assigns[:live_ex_store_topic]) do
          raise """
          You must call `init/2` first, before you can dispatch any actions.

              YourStore.init(initial_state, socket)
              store_pid = socket.assigns.live_ex_store_pid
              YourStore.dispatch(store_pid, "my_action", %{my: "payload"}, socket)

          """
        end

        action = %{type: type, payload: payload}
        send(store_pid, action)

        :ok
      end

      @doc """
      Commit a change to the store.
      """
      @spec commit(atom() | String.t(), any, socket) :: {:noreply, socket}
      @dialyzer {:no_match, commit: 3}
      def commit(type, payload, socket) do
        type = if is_atom(type), do: type, else: String.to_existing_atom(type)

        fn_apply = fn -> apply(__MODULE__, type, [payload, socket]) end

        socket =
          case unquote(log_output) do
            true -> log_and_apply(type, payload, socket, fn_apply)
            false -> fn_apply.()
          end

        {:noreply, socket}
      end

      @doc """
      Broadcast a state change to all subscribed LiveViews.
      """
      def broadcast_state_change(
            %{assigns: %{live_ex_store_topic: topic}} = socket,
            key,
            new_state
          ) do
        Phoenix.PubSub.broadcast(
          unquote(pubsub_name),
          socket.assigns.live_ex_store_topic,
          {:update_state, key, new_state}
        )
      end

      @doc """
      Helper function for assigning a new state to the socket.
      """
      def handle_state_change({:update_state, key, new_state}, socket) do
        assign(socket, key, new_state)
      end

      def handle_info({:update_state, _key, _new_state} = msg, socket) do
        {:noreply, handle_state_change(msg, socket)}
      end

      defp log_and_apply(type, payload, socket, fun) do
        state_before = socket.assigns
        socket = fun.()
        state_after = socket.assigns

        Logger.debug("LiveEx
            - Action:  #{type}
            - Payload: #{inspect(payload)}
            - Before:  #{inspect(state_before)}
            - After:   #{inspect(state_after)}
            ")

        socket
      end

      defp store_topic(store_pid) do
        "_#{__MODULE__}_store_#{inspect(store_pid)}_state_changed"
      end
    end
  end
end
