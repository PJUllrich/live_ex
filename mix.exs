defmodule LiveEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_ex,
      version: "0.3.0",
      description: "Flux based State Management for Phoenix LiveView",
      source_url: "https://github.com/PJUllrich/live_ex",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/PJUllrich/live_ex"}
      ],
      elixir: "~> 1.7",
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
      {:jason, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.18"},

      # Development and publishing dependencies
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
