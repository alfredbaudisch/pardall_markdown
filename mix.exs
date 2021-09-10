defmodule LiveMarkdown.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_markdown,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveMarkdown.Application, []},
      extra_applications: [:logger, :runtime_tools, :con_cache]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.0-rc.0", override: true},
      {:phoenix_html, "~> 3.0"},
      {:ecto_sql, "~> 3.7", override: true},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_view, "~> 0.16.0"},
      {:phoenix_live_dashboard, "~> 0.5"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:file_system, "~> 0.2"},
      {:earmark, "~> 1.4"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:slugify, "~> 1.3"},
      {:con_cache, "~> 0.13"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
