defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {MyApp.Application, []}  # ← AJOUTER CETTE LIGNE
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"},
      {:ecto_sql, "~> 3.11"},
      {:myxql, "~> 0.6.0"},
      {:bcrypt_elixir, "~> 3.0"}
    ]
  end
end
