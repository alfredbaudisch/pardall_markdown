defmodule PardallMarkdown.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Supervisor.child_spec(
        {ConCache,
         [
           name: Application.get_env(:pardall_markdown, PardallMarkdown.Content)[:cache_name],
           ttl_check_interval: false
         ]},
        id: Application.get_env(:pardall_markdown, PardallMarkdown.Content)[:cache_name]
      ),
      Supervisor.child_spec(
        {ConCache,
         [
           name:
             Application.get_env(:pardall_markdown, PardallMarkdown.Content)[:index_cache_name],
           ttl_check_interval: false
         ]},
        id: Application.get_env(:pardall_markdown, PardallMarkdown.Content)[:index_cache_name]
      ),
      {
        PardallMarkdown.FileWatcher,
        name: PardallMarkdown.FileWatcher, dirs: [PardallMarkdown.Content.Utils.root_path()]
      }
      # Start a worker by calling: PardallMarkdown.Worker.start_link(arg)
      # {PardallMarkdown.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PardallMarkdown.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
