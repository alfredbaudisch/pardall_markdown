defmodule KodaMarkdown.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      KodaMarkdownWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: KodaMarkdown.PubSub},
      # Start the Endpoint (http/https)
      KodaMarkdownWeb.Endpoint,
      Supervisor.child_spec(
        {ConCache,
         [
           name: Application.get_env(:koda_markdown, KodaMarkdown.Content)[:cache_name],
           ttl_check_interval: false
         ]},
        id: Application.get_env(:koda_markdown, KodaMarkdown.Content)[:cache_name]
      ),
      Supervisor.child_spec(
        {ConCache,
         [
           name: Application.get_env(:koda_markdown, KodaMarkdown.Content)[:index_cache_name],
           ttl_check_interval: false
         ]},
        id: Application.get_env(:koda_markdown, KodaMarkdown.Content)[:index_cache_name]
      ),
      {
        KodaMarkdown.FileWatcher,
        name: KodaMarkdown.FileWatcher, dirs: [KodaMarkdown.Content.Utils.root_path()]
      }
      # Start a worker by calling: KodaMarkdown.Worker.start_link(arg)
      # {KodaMarkdown.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KodaMarkdown.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    KodaMarkdownWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
