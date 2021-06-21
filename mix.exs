defmodule LiveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_ex,
      version: "0.1.0",
      description: "Flux based State Management for Phoenix LiveView",
      source_url: "https://github.com/PJUllrich/live_ex",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/PJUllrich/live_ex"}
      ],
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
      {:jason, "~> 1.0"},
      {:phoenix_live_view, "~> 0.15.0"}
    ]
  end
end
