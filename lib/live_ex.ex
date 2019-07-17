defmodule LiveEx do
  @moduledoc """
  Documentation for LiveEx.
  """

  @type socket :: Phoenix.LiveView.Socket.t()

  @callback init(socket) :: socket

  defmacro __using__(_opts \\ []) do
    quote do
      require Logger

      import Phoenix.LiveView, only: [assign: 3]

      @doc """
      Configures the socket with an initial setup.

      The `pid` of the parent process is stored in the `socket.assigns` so that
      Child processes can dispatch Actions on the parents's Store.
      """
      @spec init(map, socket) :: socket
      def init(state, socket) when is_map(state) do
        state
        |> Map.put_new(:pid, self())
        |> Enum.reduce(socket, fn {key, val}, socket -> assign(socket, key, val) end)
      end

      @doc """
      Dispatch an Action with a `type` and an optional payload.
      """
      def dispatch(type, payload \\ nil, socket)

      @spec dispatch(atom, any, socket) :: map
      def dispatch(type, payload, socket) when is_atom(type) do
        action = %{type: type, payload: payload}

        send(socket.assigns.pid, action)
      end

      @spec dispatch(String.t(), any, socket) :: map
      def dispatch(type, payload, socket) do
        type
        |> String.to_atom()
        |> dispatch(payload, socket)
      end

      @doc """
      Commit a change to the store.


      """
      @spec commit(atom, any, socket) :: {:noreply, socket}
      def commit(type, payload, socket) do
        socket =
          log(type, payload, socket, fn ->
            apply(__MODULE__, type, [payload, socket])
          end)

        {:noreply, socket}
      end

      defp log(type, payload, socket, fun) do
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
