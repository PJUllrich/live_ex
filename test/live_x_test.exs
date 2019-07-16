defmodule LiveXTest do
  use ExUnit.Case, async: true
  doctest LiveX

  alias LiveX.TestImpl
  alias Phoenix.LiveView.View
  alias Phoenix.LiveViewTest.{Endpoint, Router}

  # Gets called before each test.
  # Creates a LiveView socket and adds it to the test `context`.
  setup do
    socket =
      Endpoint
      |> View.build_socket(Router, %{connected?: true})
      |> View.post_mount_prune()

    [socket: socket]
  end

  describe "init" do
    test "init sets initial state", context do
      state = [a: 1, b: "Test", c: nil]
      socket = TestImpl.init(state, context[:socket])

      assert socket.assigns.a == Keyword.get(state, :a)
      assert socket.assigns.b == Keyword.get(state, :b)
      assert socket.assigns.c == Keyword.get(state, :c)
    end

    test "init raises when initial state is no Keyword List", context do
      state_map = %{a: 1, b: "Test", c: nil}
      state_list = [:a, :b, :c]

      assert_raise FunctionClauseError, fn ->
        TestImpl.init(state_map, context[:socket])
      end

      assert_raise FunctionClauseError, fn ->
        TestImpl.init(state_list, context[:socket])
      end
    end
  end

  describe "dispatch" do
    test "dispatch sends event to Store PID", context do
      socket = TestImpl.init(context[:socket])

      event = %{
        type: "test_event",
        payload: "test_payload"
      }

      TestImpl.dispatch(event.type, event.payload, socket)
      assert_receive(event)
    end

    test "dispatch raises when `init` was not called", context do
      assert_raise KeyError, fn ->
        TestImpl.dispatch("test", "test", context[:socket])
      end
    end
  end

  describe "commit" do
    test "commit updates the no_payload state", context do
      socket = TestImpl.init(context[:socket])
      socket = TestImpl.commit(:no_payload, %{}, socket)

      assert socket.assigns.no_payload == true
    end

    test "commit updates the with_payload state", context do
      socket = TestImpl.init(context[:socket])
      socket = TestImpl.commit(:with_payload, "updated_state", socket)

      assert socket.assigns.with_payload == "updated_state"
    end
  end
end
