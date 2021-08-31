defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.Content

  @cache_name Application.compile_env(:live_markdown, [LiveMarkdown.Content, :cache_name])
  @index_cache_name Application.compile_env(:live_markdown, [
                      LiveMarkdown.Content,
                      :index_cache_name
                    ])

  def get_by_slug(slug) do
    ConCache.get(@cache_name, get_key(slug))
  end

  def get_all do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.map(fn {_, value} -> value end)
  end

  def save(%Content{slug: slug, file_path: path} = value) do
    key = get_key(slug)
    Logger.info("[Content.Cache] saved #{inspect(key)}, #{inspect(value)}")
    ConCache.put(@cache_name, key, value)
    ConCache.put(@index_cache_name, get_path_key(path), key)
  end

  def save_path(path, contents) do
    ConCache.put(@index_cache_name, get_path_key(path), contents)
  end

  @doc """
  Recursively delete a path from cache.
  Returns a map indexed by the deleted paths' slugs and value `:deleted`.
  """
  def delete_path(path, results \\ %{}) do
    key = get_path_key(path)
    path_contents = ConCache.get(@index_cache_name, key)
    ConCache.delete(@index_cache_name, key)

    case path_contents do
      {:slug, slug} ->
        delete_slug(slug)
        Map.put(results, slug, :deleted)

      [%{path: _} | _] = posts ->
        Enum.reduce(posts, results, fn %{path: p, slug: s}, inner_results ->
          inner_results
          |> Map.put(s, :deleted)
          |> Map.merge(delete_path(p, inner_results))
        end)

      _ ->
        results
    end
  end

  def delete_slug(slug) do
    ConCache.delete(@cache_name, get_key(slug))
  end

  def delete_all do
    ConCache.ets(@cache_name)
    |> :ets.delete_all_objects()

    ConCache.ets(@index_cache_name)
    |> :ets.delete_all_objects()
  end

  defp get_key(slug), do: {:slug, slug}
  defp get_path_key(path), do: {:path, path}
end
