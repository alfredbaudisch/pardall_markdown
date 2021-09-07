defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.{Post, Link}
  alias __MODULE__.Item
  import LiveMarkdown.Content.Repository.Filters

  @cache_name Application.compile_env(:live_markdown, [LiveMarkdown.Content, :cache_name])
  @index_cache_name Application.compile_env(:live_markdown, [
                      LiveMarkdown.Content,
                      :index_cache_name
                    ])

  def get_by_slug(slug) do
    case ConCache.get(@cache_name, slug_key(slug)) do
      %Item{value: value} -> value
      nil -> nil
    end
  end

  def get_all_posts do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.reject(fn {_, %Item{type: type}} -> type == :link end)
    |> Enum.map(fn {_, %Item{value: value}} -> value end)
  end

  def get_all_taxonomies do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.reject(fn {_, %Item{type: type}} -> type != :link end)
    |> Enum.map(fn {_, %Item{value: value}} -> value end)
  end

  def get_taxonomy_tree(sort_by \\ :title) when sort_by in [:title, :date] do
    get = fn -> ConCache.get(@index_cache_name, taxonomy_tree_key(sort_by)) end

    case get.() do
      nil ->
        build_taxonomy_tree()
        get.()

      tree ->
        tree
    end
  end

  def get_content_tree(sort_by \\ :title) when sort_by in [:title, :date] do
    get = fn -> ConCache.get(@index_cache_name, content_tree_key(sort_by)) end

    case get.() do
      nil ->
        build_content_tree()
        get.()

      tree ->
        tree
    end
  end

  def save_post(%Post{} = post) do
    save_post_pure(post)
    save_post_taxonomies(post)
  end

  def save_post_pure(%Post{slug: slug, file_path: path} = post) do
    key = slug_key(slug)
    ConCache.put(@cache_name, key, Item.new_post(post))
    ConCache.put(@index_cache_name, path_key(path), key)

    Logger.info("Saved #{inspect(key)}")
    Logger.debug("#{inspect(key)} contents: #{inspect(post)}")
  end

  def save_path(path, contents) do
    ConCache.put(@index_cache_name, path_key(path), contents)
  end

  def upsert_taxonomy_appending_post(
        %Link{slug: slug, children: children} = taxonomy,
        %Post{} = post
      ) do
    do_update = fn taxonomy, children ->
      {:ok, Item.new_link(%{taxonomy | children: children ++ [Map.put(post, :content, nil)]})}
    end

    ConCache.update(@cache_name, slug_key(slug), fn
      nil ->
        do_update.(taxonomy, children)

      %Item{type: :link, value: %{children: children} = taxonomy} ->
        do_update.(taxonomy, children)
    end)
  end

  # TODO: For the initial purpose of this project, this solution is ok,
  # but eventually let's implement it with a "real" tree or linked list.
  def build_taxonomy_tree do
    tree =
      get_all_taxonomies()
      |> sort_by_slug()
      |> Enum.map(fn %Link{children: posts, slug: slug} = taxonomy ->
        posts =
          posts
          |> Enum.filter(fn
            %Post{taxonomies: [_t | _] = post_taxonomies} ->
              # The last taxonomy of a post is its parent taxonomy.
              # I.e. a post in *Blog > Art > 3D* has 3 taxonomies:
              # Blog, Blog > Art and Blog > Art > 3D,
              # where its parent is the last one.
              List.last(post_taxonomies).slug == slug

            _ ->
              true
          end)
          |> filter_by_is_published()

        taxonomy
        |> Map.put(:children, posts)
      end)

    tree_with_posts_by_date =
      tree
      |> Enum.map(fn %Link{children: posts} = taxonomy ->
        taxonomy
        |> Map.put(:children, posts |> sort_by_published_date())
      end)

    tree_with_posts_by_title =
      tree
      |> Enum.map(fn %Link{children: posts} = taxonomy ->
        taxonomy
        |> Map.put(:children, posts |> sort_by_title())
      end)

    ConCache.put(@index_cache_name, taxonomy_tree_key(:date), tree_with_posts_by_date)
    ConCache.put(@index_cache_name, taxonomy_tree_key(:title), tree_with_posts_by_title)
    %{date: tree_with_posts_by_date, title: tree_with_posts_by_title}
  end

  def find_and_save_siblings do
  end

  # Posts are extracted from the `children` field of a taxonomy
  # and added to the taxonomies list as a Link, while keeping
  # the correct nesting under their parent taxonomy.
  def build_content_tree do
    %{date: tree_with_posts_by_date, title: tree_with_posts_by_title} = build_taxonomy_tree()

    by_date = do_build_content_tree(tree_with_posts_by_date)
    by_title = do_build_content_tree(tree_with_posts_by_title)

    ConCache.put(@index_cache_name, content_tree_key(:date), by_date)
    ConCache.put(@index_cache_name, content_tree_key(:title), by_title)
    %{date: by_date, title: by_title}
  end

  @doc """
  Recursively delete a path from cache.
  Returns a map indexed by the deleted paths' slugs and value `:deleted`.
  """
  def delete_path(path, results \\ %{}) do
    key = path_key(path)
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
    ConCache.delete(@cache_name, slug_key(slug))
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

  defp save_post_taxonomies(%Post{taxonomies: taxonomies} = post) do
    taxonomies
    |> Enum.map(&upsert_taxonomy_appending_post(&1, post))
  end

  defp do_build_content_tree(tree) do
    tree
    |> Enum.reduce([], fn %Link{children: posts, parents: parents} = taxonomy, all ->
      all
      |> Kernel.++([Map.put(taxonomy, :children, [])])
      |> Kernel.++(
        posts
        |> Enum.map(fn post ->
          %Link{
            slug: post.slug,
            title: post.title,
            level: level_for_joined_post(taxonomy.slug, taxonomy.level),
            parents: parents,
            type: "post"
          }
        end)
      )
    end)
  end

  defp level_for_joined_post(parent_slug, parent_level) when parent_slug == "/",
    do: parent_level

  defp level_for_joined_post(_, parent_level), do: parent_level + 1

  defp slug_key(slug), do: {:slug, slug}
  defp path_key(path), do: {:path, path}
  defp taxonomy_tree_key(sort_posts_by), do: {:taxonomy_tree, sort_posts_by}

  defp content_tree_key(sort_posts_by),
    do: {:taxonomy_tree_joined_posts, sort_posts_by}
end
