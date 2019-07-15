defmodule LiveX do
  @moduledoc """
  Documentation for LiveX.
  """

  import Phoenix.LiveView, only: [assign: 3]

  @doc """
  Configures the socket with an initial setup.

  The `pid` of the parent process is stored in the `socket.assigns` so that
  Child processes can dispatch Actions on the parents's Store.
  """
  def init(initial_state, socket) do
    socket
    |> assign(:state, initial_state)
    |> assign(:pid, self())
  end

  @doc """
  Joins a child process to the Store of a parent process.
  """
  def join(params, socket) do
    socket
    |> assign(:state, params.state)
    |> assign(:pid, params.pid)
  end

  @doc """
  Dispatch an Action with a `type`, optional payload.
  """
  def dispatch(type, payload \\ %{}, socket) do
    event = %{
      type: String.to_atom(type),
      payload: payload
    }

    send(socket.assigns.pid, event)
  end

  def commit(type, payload, socket) do
    apply(__MODULE__, type, [socket, payload])
  end
end
