defmodule LiveEx.Example do
  @moduledoc """
  Example Implementation of a LiveEx Store that is used by `Phoenix.LiveView`s.
  """

  use LiveEx

  # Optional and for type-safety during development only
  @behaviour LiveEx
  @type socket :: Phoenix.LiveView.Socket.t()

  # Set an initial (global) state.
  # Set all variables that are part of the global state.
  @initial_state %{
    no_payload: false,
    with_payload: "default"
  }

  @doc """
  Call this function from the `mount/2` function of your "root"-LiveView.

  Adds the initial state variables to the `socket.assigns` and returns the updated `LiveView.Socket`.
  """
  @spec init(socket) :: socket
  def init(socket) do
    init(@initial_state, socket)
  end

  # Actions
  #
  # Define any Actions below.
  #
  # Actions must be `handle_info/2` GenServer Event Handlers that are pattern-matched
  # against the action `type`.
  #
  # Actions must call the `commit/3` function and return what the `commit/3` function returns.

  @doc """
  Handles the `type: :no_payload` dispatch and commits the `:no_payload` Mutation.

  `action` here has the format: `%{type: :no_payload, payload: %{}}`
  """
  @spec handle_info(%{type: atom, payload: map}, socket) :: {:noreply, socket}
  def handle_call(%{type: :no_payload} = action, socket) do
    commit(action.type, %{}, socket)
  end

  @doc """
  Handles the `type: :with_payload` dispatch and commits the `:with_payload` Mutation.

  `action` here has the format: `%{type: :with_payload, payload: any}`
  """
  def handle_info(%{type: :with_payload} = action, socket) do
    commit(action.type, action.payload, socket)
  end

  # Mutations
  #
  # Define any Mutations below.
  #
  # Mutations must have the same name as the action `type`.
  # Mutations update the `socket.assigns` with the `assign/3` function.
  #
  # Mutations must return the updated `LiveView.Socket`.

  @doc """
  Mutates the `:no_payload` variable of the store.
  """
  @spec no_payload(map, socket) :: socket
  def no_payload(%{}, socket) do
    assign(socket, :no_payload, !socket.assigns.no_payload)
  end

  @spec with_payload(map, socket) :: socket
  def with_payload(payload, socket) do
    assign(socket, :with_payload, payload)
  end
end
