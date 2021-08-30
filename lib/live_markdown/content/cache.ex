defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.Content

  @cache_name Application.compile_env(:live_markdown, [LiveMarkdown.Content, :cache_name])
  @index_cache_name Application.compile_env(:live_markdown, [
                      LiveMarkdown.Content,
                      :index_cache_name
                    ])

  def save(%Content{slug: slug, file_path: path} = value) do
    key = get_key(slug)
    Logger.info("[Content.Cache] saved #{inspect(key)}, #{inspect(value)}")
    ConCache.put(@cache_name, key, value)
    ConCache.put(@index_cache_name, get_path_key(path), key)
  end

  def get_by_slug(slug) do
    ConCache.get(@cache_name, get_key(slug))
  end

  def get_all do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.map(fn {_, value} -> value end)
  end

  defp get_key(slug), do: {:slug, slug}
  defp get_path_key(path), do: {:path, path}
end
