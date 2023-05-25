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

      import Phoenix.Component, only: [assign: 3, assign_new: 3]

      @doc """
      Configures the socket with an initial setup.

      The `pid` of the parent process is stored in the `socket.assigns` so that
      Child processes can dispatch Actions on the parents's Store.
      """
      @spec init(map, socket) :: socket
      def init(state, socket) when is_map(state) do
        socket =
          state
          |> Map.put_new(:live_ex_store_topic, "_live_ex_store_topic_#{inspect(self())}")
          |> Enum.reduce(socket, fn {key, val}, socket ->
            assign_new(socket, key, fn -> val end)
          end)

        :ok = Phoenix.PubSub.unsubscribe(unquote(pubsub_name), socket.assigns.live_ex_store_topic)
        :ok = Phoenix.PubSub.subscribe(unquote(pubsub_name), socket.assigns.live_ex_store_topic)

        socket
      end

      @doc """
      Dispatch an Action with a `type` and an optional payload.
      """
      @spec dispatch(String.t(), any, socket) :: :ok | {:error, term}
      def dispatch(type, payload \\ nil, socket) when is_binary(type) do
        action = %{type: type, payload: payload}

        Phoenix.PubSub.broadcast(unquote(pubsub_name), socket.assigns.live_ex_store_topic, action)
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
    end
  end
end
