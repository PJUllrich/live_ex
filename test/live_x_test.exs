defmodule LiveExTest do
  use ExUnit.Case, async: false
  doctest LiveEx

  alias LiveEx.Example
  alias Phoenix.LiveView.{Utils, Socket}
  alias Phoenix.LiveViewTest.Endpoint

  setup_all do
    {:ok, _} =
      Supervisor.start_link([Phoenix.PubSub.child_spec(name: :live_ex_pubsub)],
        strategy: :one_for_one
      )

    :ok
  end

  setup do
    # Create a socket manually
    # Taken from: https://github.com/phoenixframework/phoenix_live_view/blob/28f3c6d4a2b534a4a9a8dc7e2e7ccd5c751345c7/test/phoenix_live_view_test.exs#L9
    socket =
      %Socket{
        endpoint: Endpoint,
        router: Phoenix.LiveViewTest.Router,
        view: Phoenix.LiveViewTest.ParamCounterLive
      }
      |> Utils.configure_socket(
        %{
          connect_params: %{},
          connect_info: %{},
          root_view: Phoenix.LiveViewTest.ParamCounterLive,
          __changed__: %{}
        },
        nil,
        %{},
        URI.parse("https://www.example.com")
      )
      |> Map.merge(%{transport_pid: self()})
      |> Utils.post_mount_prune()

    [socket: socket]
  end

  describe "init" do
    test "sets initial state", context do
      state = %{a: 1, b: "Test", c: nil}
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

    @doc """
    As we call init in at least two places it's important to make sure that double subscription does not occur
    otherwise it leads to double event dispatch which is harmful for events with side effects
    """
    test "avoids double subscription when called multiple times", context do
      state = %{a: 1, b: "Test", c: nil}

      socket = Example.init(state, context[:socket])
      Example.init(state, socket)

      event = %{
        type: "test_event",
        payload: "test_payload"
      }

      :ok = Example.dispatch(event.type, event.payload, socket)
      assert_received(^event)
      refute_receive(^event)
    end
  end

  describe "dispatch" do
    test "broadcasts an event to PubSub", context do
      socket = Example.init(context[:socket])

      event = %{
        type: "test_event",
        payload: "test_payload"
      }

      :ok = Example.dispatch(event.type, event.payload, socket)
      assert_receive ^event
    end

    test "raises when `init` was not called before dispatching", context do
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

    test "accepts string-based action types", context do
      socket = Example.init(context[:socket])
      {:noreply, socket} = Example.commit("with_payload", "updated_state", socket)

      assert socket.assigns.with_payload == "updated_state"
    end
  end
end
