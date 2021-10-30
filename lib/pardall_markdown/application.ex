defmodule PardallMarkdown.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    config = PardallMarkdown.Config.validate_and_get_startup_config!()

    children = [
      Supervisor.child_spec(
        {ConCache,
         [
           name: config.cache_name,
           ttl_check_interval: false
         ]},
        id: config.cache_name
      ),
      Supervisor.child_spec(
        {ConCache,
         [
           name: config.index_cache_name,
           ttl_check_interval: false
         ]},
        id: config.index_cache_name
      ),
      {
        PardallMarkdown.FileWatcher,
        name: PardallMarkdown.FileWatcher, dirs: [config.root_path]
      }
    ]
    |> maybe_append_repository_watcher(config.remote_repository_url)

    opts = [strategy: :one_for_one, name: PardallMarkdown.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_append_repository_watcher(children, url) when is_nil(url) or url == "", do: children
  defp maybe_append_repository_watcher(children, url) do
    children ++
    [{
      PardallMarkdown.RepositoryWatcher,
      name: PardallMarkdown.RepositoryWatcher, repo: url
    }]
  end
end
