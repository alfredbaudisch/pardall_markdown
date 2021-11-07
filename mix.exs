defmodule PardallMarkdown.MixProject do
  use Mix.Project

  @url "https://github.com/alfredbaudisch/pardall_markdown"
  @version "0.4.2"

  def project do
    [
      app: :pardall_markdown,
      name: "PardallMarkdown",
      version: @version,
      elixir: "~> 1.7",
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      description:
        "Reactive publishing framework, filesystem-based with support for Markdown, nested hierarchies, and instant content rebuilding. Written in Elixir."
    ]
  end

  def application do
    [
      mod: {PardallMarkdown.Application, []},
      extra_applications: [:logger, :con_cache]
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.7"},
      {:floki, "~> 0.31.0"},
      {:file_system, "~> 0.2"},
      {:earmark, "~> 1.4"},
      {:slugify, "~> 1.3"},
      {:html_entities, "~> 0.5"},
      {:con_cache, "~> 0.13"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:git_cli, "~> 0.3"},
    ]
  end

  defp package do
    %{
      licenses: ["Apache 2.0"],
      maintainers: ["Alfred Reinold Baudisch"],
      links: %{"GitHub" => @url}
    }
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @url,
      source_ref: @version,
      formatters: ["html"]
    ]
  end
end
