defmodule InstaMarkdown.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      InstaMarkdown.Repo,
      # Start the Telemetry supervisor
      InstaMarkdownWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: InstaMarkdown.PubSub},
      # Start the Endpoint (http/https)
      InstaMarkdownWeb.Endpoint,
      {
        InstaMarkdown.FileWatcher,
        name: InstaMarkdown.FileWatcher, dirs: ["/home/alfredbaudisch/Documents/content"]
      }
      # Start a worker by calling: InstaMarkdown.Worker.start_link(arg)
      # {InstaMarkdown.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InstaMarkdown.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    InstaMarkdownWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
