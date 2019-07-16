defmodule LiveX do
  @moduledoc """
  Documentation for LiveX.
  """

  @callback init(LiveView.Socket) :: LiveView.Socket

  defmacro __using__(_opts \\ []) do
    quote do
      require Logger

      import Phoenix.LiveView, only: [assign: 3]

      @doc """
      Configures the socket with an initial setup.

      The `pid` of the parent process is stored in the `socket.assigns` so that
      Child processes can dispatch Actions on the parents's Store.
      """
      def init(state, socket) when is_map(state) do
        state
        |> Map.put_new(:pid, self())
        |> Enum.reduce(socket, fn {key, val}, socket -> assign(socket, key, val) end)
      end

      @doc """
      Dispatch an Action with a `type` and an optional payload.
      """
      def dispatch(type, payload \\ %{}, socket) do
        event = %{
          type: String.to_atom(type),
          payload: payload
        }

        send(socket.assigns.pid, event)
      end

      @doc """
      Commit a change to the store.


      """
      def commit(type, payload, socket) do
        log(type, payload, socket, fn ->
          apply(__MODULE__, type, [payload, socket])
        end)
      end

      defp log(type, payload, socket, fun) do
        state_before = socket.assigns
        socket = fun.()
        state_after = socket.assigns

        Logger.debug("LiveX
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
