defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.{Post, Taxonomy}
  alias __MODULE__.Item
  import LiveMarkdown.Content.Repository.Filters

  @cache_name Application.compile_env(:live_markdown, [LiveMarkdown.Content, :cache_name])
  @index_cache_name Application.compile_env(:live_markdown, [
                      LiveMarkdown.Content,
                      :index_cache_name
                    ])

  def get_by_slug(slug) do
    case ConCache.get(@cache_name, get_slug_key(slug)) do
      %Item{value: value} -> value
      nil -> nil
    end
  end

  def get_all_posts do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.reject(fn {_, %Item{type: type}} -> type == :taxonomy end)
    |> Enum.map(fn {_, %Item{value: value}} -> value end)
  end

  def get_all_taxonomies do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.reject(fn {_, %Item{type: type}} -> type != :taxonomy end)
    |> Enum.map(fn {_, %Item{value: value}} -> value end)
  end

  def get_taxonomy_tree do
    ConCache.get(@index_cache_name, get_taxonomy_tree_key())
  end

  def save_post(%Post{slug: slug, file_path: path} = value) do
    key = get_slug_key(slug)
    ConCache.put(@cache_name, key, Item.new_post(value))
    ConCache.put(@index_cache_name, get_path_key(path), key)

    Logger.info("Saved #{inspect(key)}")
    Logger.debug("#{inspect(key)} contents: #{inspect(value)}")
  end

  def save_path(path, contents) do
    ConCache.put(@index_cache_name, get_path_key(path), contents)
  end

  def save_taxonomy_with_post(
        %Taxonomy{slug: slug, children: children} = taxonomy,
        %Post{} = post
      ) do
    do_update = fn taxonomy, children ->
      {:ok, Item.new_taxonomy(%{taxonomy | children: children ++ [Map.put(post, :content, nil)]})}
    end

    ConCache.update(@cache_name, get_slug_key(slug), fn
      nil ->
        do_update.(taxonomy, children)

      %{type: :taxonomy, value: %{children: children} = taxonomy} ->
        do_update.(taxonomy, children)
    end)

    build_and_save_taxonomy_tree()
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
    ConCache.delete(@cache_name, get_slug_key(slug))
  end

  def delete_all do
    ConCache.ets(@cache_name)
    |> :ets.delete_all_objects()

    ConCache.ets(@index_cache_name)
    |> :ets.delete_all_objects()
  end

  #
  # Internal
  #

  defp build_and_save_taxonomy_tree do
    tree =
      get_all_taxonomies()
      |> Enum.map(fn %Taxonomy{children: posts, slug: slug} = taxonomy ->
        posts =
          posts
          |> Enum.filter(fn
            %Post{taxonomies: [_t | _] = post_tax} ->
              List.last(post_tax).slug == slug

            _ ->
              true
          end)

        taxonomy
        |> Map.put(:children, posts)
      end)
      |> sort_by_slug()

    ConCache.put(@index_cache_name, get_taxonomy_tree_key(), tree)
  end

  defp get_slug_key(slug), do: {:slug, slug}
  defp get_path_key(path), do: {:path, path}
  defp get_taxonomy_tree_key, do: :taxonomy_tree
end
