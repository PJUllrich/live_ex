Application.put_env(:phoenix_pubsub, :test_adapter, {Phoenix.PubSub.PG2, []})
Supervisor.start_link(
  [{Phoenix.PubSub, name: :live_ex_pubsub, pool_size: 1}],
  strategy: :one_for_one
)

ExUnit.start()
