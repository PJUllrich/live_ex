# LiveEx - State Management for Phoenix LiveViews

## Heads up: This library is not actively developed further
> This library was initially meant as a Proof of Concept and until today, I haven't used it in a production system (simply because I haven't had a use-case for it).
>
> I'm currently only updating its dependencies, but would like to develop it further. However, I don't have the information about what you, the user, needs or misses from the library. That's why I ask you kindly to open an issue for feature requests or other development ideas. I'm open to develop this library further, but am dependent on your input on how to do so.
> 
> Thank you in advance!

LiveEx is a State Management library for [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view).

LiveEx is based on the [Flux pattern](https://github.com/facebook/flux/tree/master/examples/flux-concepts)
and its implementation is inspired by the [Vuex](https://vuex.vuejs.org/) library.

## What is the Flux pattern?

The Flux pattern tries to solve the problem of middle to large single-page applications (SPAs) that
the oversight of which state changes are applied when and from where can be lost easily. Additionally, the
information flow within a reasonably sized SPA becomes exponentially more complex the more the SPA grows in terms of components.

The Flux pattern proposes the solution a `Store` for the state of the SPA that can only be changed through a `Dispatcher`,
which can be seen as a funnel through which every state change has to pass before it is applied. This sequentializing of
state changes helps to keep an overview of when and how the state was changed. The information flows become much clearer
since they are represented by the sequence and order of state changes.

The diagram below shows the flow of the Flux pattern. A state change is initiated by dispatching an `Action`, which has a `type` and an optional `payload`.
The `Action` then commits a `Mutation`, which actually mutates/changes the state. The new state is then saved in the `Store` again. The `Store` notifies
the views that a state updates is available.

![flux pattern diagram](/docs/images/flux.png)

## Why this library?

I completed a medium-sized project using LiveView recently in which I used 2 nested LiveViews. I ran into the typical problem that I lost the oversight of how and when the state shared by the 2 LiveViews changed and whether the views transitioned from one state to another without state corruption (e.g. some variable wasn't updated properly). Therefore, I created this project to help you (and me) to use LiveView for larger than example projects.

## Installation

Add `live_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_ex, github: "pjullrich/live_ex" }
  ]
end
```

## How to use

Have a look at the [Example Implementation](https://github.com/PJUllrich/LiveEx/blob/master/lib/example/example.ex) for a fully documented implementation of a `LiveEx Store`.

### Initialize the Store

In order to use the LiveEx Store, create a dedicated `module` for it, which adheres to the following structure:

```elixir
defmodule MyAppWeb.Store do
  use LiveEx

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

  def handle_info(%{type: "my_action"} = action, socket) do
    # Perform any operation with the payload here. For example:
    new_state = socket.assigns.a + action.payload

    commit("my_action", new_state, socket)
  end

  # Mutations

  def my_action(payload, socket) do
    assign(socket, :a, payload)
  end
end
```

Initialize the `Store` in the `mount/2` function of your outermost (i.e. `root`) LiveView, which encapsulates the nested (i.e. `child`) LiveViews. Since the LiveEx store currently runs in the same process as your `root` LiveView, we need delegate any Action callbacks (i.e. `handle_info`) to the Store module. Add the `defdelegate` line **below** any `handle_info` calls you want to make in your LiveView.

```elixir
alias MyAppWeb.Store

...

def mount(_session, socket) do
  {:ok, Store.init(socket)}
end

...

defdelegate handle_info(msg, socket), to: Store
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
1. Update the test implementation in `lib/test/test_impl.ex` whenever you make changes to `lib/live_ex.ex`
