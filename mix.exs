defmodule LiveX.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_x,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:phoenix_live_view, github: "phoenixframework/phoenix_live_view"}
    ]
  end
end
