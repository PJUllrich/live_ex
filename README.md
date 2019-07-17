# LiveX - State Management for Phoenix LiveViews

LiveX is a State Management library for [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view).

LiveX is based on the [Flux pattern](https://github.com/facebook/flux/tree/master/examples/flux-concepts)
and its implementation is inspired by the [Vuex](https://vuex.vuejs.org/) library.

LiveX helps organize the state changes and data flow in LiveView frontends.
State changes (aka. `Actions`) are forced through a `Dispatcher` (or funnel) in a sequencial FIFO manner before
the changes are applied to a global state managed by a `Store`. The same store can be shared by multiple LiveViews.

The following diagram shows the flow of the Flux pattern:

![flux pattern diagram](/docs/images/flux.png)

## Installation

Add `live_x` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_x, github: "pjullrich/liveX" }
  ]
end
```

## How to use

Have a look at the [Example Implementation](https://github.com/PJUllrich/LiveX/blob/master/lib/example/example.ex) for a fully documented implementation of a `LiveX Store`.

### Initialize the Store

In order to use the LiveX Store, create a dedicated `module` for it, which adhere's to the following structure:

```elixir
defmodule MyAppWeb.Store do
  use LiveX

  @initial_store %{
    a: 1,
    b: "test",
    c: true,
    d: [nil, nil, nil]
  }

  def init(socket) do
    init(@initial_store, socket)
  end

  # Actions

  def handle_info(%{type: :my_action} = action, socket) do
    # Perform any operation with the payload here. For example:
    new_state = socket.assigns.a + action.payload

    commit(:my_action, new_state, socket)
  end

  # Mutations

  def my_action(payload, socket) do
    assign(socket, :a, payload)
  end
end
```

Initialize the `Store` in the `mount/2` function of your outermost (i.e. `root`) LiveView, which encapsulates the nested (i.e. `child` )LiveViews.

```elixir
def mount(_session, socket) do
  {:ok, MyAppWeb.Store.init(socket)}
end
```

Pass all `Store` variables to nested LiveViews and initialize the `Store` within their `mount/2` function as well.

**root.html.leex**

```elixir
<%= Phoenix.LiveView.live_render(@socket, MyAppWeb.ChildLive, session: Map.take(assigns, [:a, :b, :c, :d])) %>
```

**child_live.ex**

```elixir
def mount(session, socket) do
  {:ok, Store.init(session, socket)}
end
```

### Dispatch Actions

If you want to dispatch an action from any LiveView, simply call the `dispatch/3` function with an action `type` and optional `payload`. For example:

**child_live.ex**

```elixir
def handle_event("increment" = event, _value, socket) do
  Store.dispatch(event, socket)
  {:noreply, socket}
end

def handle_event("add" = event, value, socket) do
  Store.dispatch(event, value, socket)
  {:noreply, socket}
end
```

## Discussion

### Store and Root LiveView run in the same Process

The current version adds the `Store` functionality to the `root` LiveView process. An alternative would be to start the `Store` in an independent `GenServer` process to separate the `Store` functionality from the `root` LiveView functionality. I added an initial (unfinished) implementation in the `feature/integrate-genserver` branch. Unfortunately, moving the `Store` to its own process means adding a lot of boilerplate code that handles the communication between the `root` LiveView, from where one has to replace the "old" socket with the "updated" socket.
If you ever run into performance issues caused by having both `Store` and `root` functionality run in the same process, consider this approach.

### Make everything synchronous

Currently, the `dispatch/3` function sends a message to its own process to avoid that a `Store` update blocks the LiveView at times when many state changes occur. One could argue that it would be better to remove the `send/2` call and handle everything synchronously. If you have an opinion on this, please don't hesitate to open an issue.

## Development

1. Checkout the project and run tests with `mix test`.
1. Update the test implementation in `lib/test/test_impl.ex` whenever you make changes to `lib/live_x.ex`
