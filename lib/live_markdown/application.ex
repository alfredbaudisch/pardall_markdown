defmodule LiveMarkdown.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveMarkdownWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveMarkdown.PubSub},
      # Start the Endpoint (http/https)
      LiveMarkdownWeb.Endpoint,
      {
        LiveMarkdown.FileWatcher,
        name: LiveMarkdown.FileWatcher, dirs: [LiveMarkdown.Content.Utils.root_folder()]
      },
      Supervisor.child_spec(
        {ConCache,
         [
           name: Application.get_env(:live_markdown, LiveMarkdown.Content)[:cache_name],
           ttl_check_interval: false
         ]},
        id: Application.get_env(:live_markdown, LiveMarkdown.Content)[:cache_name]
      ),
      Supervisor.child_spec(
        {ConCache,
         [
           name: Application.get_env(:live_markdown, LiveMarkdown.Content)[:index_cache_name],
           ttl_check_interval: false
         ]},
        id: Application.get_env(:live_markdown, LiveMarkdown.Content)[:index_cache_name]
      )
      # Start a worker by calling: LiveMarkdown.Worker.start_link(arg)
      # {LiveMarkdown.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveMarkdown.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LiveMarkdownWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
