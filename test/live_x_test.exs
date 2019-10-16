defmodule LiveExTest do
  use ExUnit.Case, async: false
  doctest LiveEx

  alias LiveEx.Example
  alias Phoenix.LiveView.{View, Socket}
  alias Phoenix.LiveViewTest.Endpoint

  # Gets called before each test.
  # Creates a LiveView socket and adds it to the test `context`.
  setup do
    Phoenix.PubSub.PG2.start_link(:live_ex_pubsub, [])

    socket =
      %Socket{endpoint: Endpoint}
      |> View.configure_socket(%{})
      |> Map.merge(%{connected?: true})
      |> View.post_mount_prune()

    [socket: socket]
  end

  describe "init" do
    test "sets initial state", context do
      state = %{"d" => "Test", a: 1, b: "Test", c: nil}
      socket = Example.init(state, context[:socket])

      assert socket.assigns.a == Map.get(state, :a)
      assert socket.assigns.b == Map.get(state, :b)
      assert socket.assigns.c == Map.get(state, :c)
    end

    test "raises when initial state is no map List", context do
      state_keyword = [a: 1, b: "Test", c: nil]
      state_list = [:a, :b, :c]

      assert_raise FunctionClauseError, fn ->
        Example.init(state_keyword, context[:socket])
      end

      assert_raise FunctionClauseError, fn ->
        Example.init(state_list, context[:socket])
      end
    end
  end

  describe "dispatch" do
    test "sends event to Store PID", context do
      socket = Example.init(context[:socket])

      event = %{
        type: "test_event",
        payload: "test_payload"
      }

      :ok = Example.dispatch(event.type, event.payload, socket)
      assert_receive event, 1_000
    end

    test "raises when `init` was not called", context do
      assert_raise KeyError, fn ->
        Example.dispatch("test", "test", context[:socket])
      end
    end
  end

  describe "commit" do
    test "updates the no_payload state", context do
      socket = Example.init(context[:socket])
      {:noreply, socket} = Example.commit(:no_payload, %{}, socket)

      assert socket.assigns.no_payload == true
    end

    test "updates the with_payload state", context do
      socket = Example.init(context[:socket])
      {:noreply, socket} = Example.commit(:with_payload, "updated_state", socket)

      assert socket.assigns.with_payload == "updated_state"
    end
  end
end
