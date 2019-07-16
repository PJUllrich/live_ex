defmodule LiveX.TestImpl do
  @moduledoc """
  Example/Test Implementation of a LiveX Store that is used by `Phoenix.LiveView`s.
  """

  use LiveX

  @behaviour LiveX

  @initial_state %{
    no_payload: false,
    with_payload: "default"
  }

  def init(socket) do
    init(@initial_state, socket)
  end

  # Actions

  def handle_event(%{type: :no_payload} = action, socket) do
    socket = commit(action.type, action.payload, socket)
    {:noreply, socket}
  end

  def handle_event(%{type: :with_payload} = action, socket) do
    socket = commit(action.type, action.payload, socket)
    {:noreply, socket}
  end

  # Mutations

  def no_payload(%{}, socket) do
    assign(socket, :no_payload, !socket.assigns.no_payload)
  end

  def with_payload(payload, socket) do
    assign(socket, :with_payload, payload)
  end
end
