defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.{Post, Link}
  alias __MODULE__.Item
  import LiveMarkdown.Content.Repository.Filters

  @cache_name Application.compile_env!(:live_markdown, [LiveMarkdown.Content, :cache_name])
  @index_cache_name Application.compile_env!(:live_markdown, [
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

  def get_taxonomy_tree(sort_by \\ :date) when sort_by in [:date] do
    get = fn -> ConCache.get(@index_cache_name, taxonomy_tree_key(sort_by)) end

    case get.() do
      nil ->
        build_taxonomy_tree()
        get.()

      tree ->
        tree
    end
  end

  def get_content_tree(sort_by \\ :date) when sort_by in [:date] do
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

  def save_post_pure(%Post{slug: slug} = post) do
    key = slug_key(slug)
    ConCache.put(@cache_name, key, Item.new_post(post))
  end

  def update_post_field(slug, field, value) do
    case get_by_slug(slug) do
      nil -> nil
      %Post{} = post -> post |> Map.put(field, value) |> save_post_pure()
    end
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

  def build_taxonomy_tree() do
    tree = do_build_taxonomy_tree()
    ConCache.put(@index_cache_name, taxonomy_tree_key(:date), tree)
    tree
  end

  # Posts are extracted from the `children` field of a taxonomy
  # and added to the taxonomies list as a Link, while keeping
  # the correct nesting under their parent taxonomy.
  def build_content_tree do
    tree =
      do_build_taxonomy_tree(true)
      |> do_build_content_tree()

    # Embed each post `%Link{}` into their individual `%Post{}` entities
    # Notice: this currently breaks the logic of sorting by title or by date,
    # since the links from "by_date" are inserted into the posts.
    Enum.each(tree, fn
      %Link{type: "post", slug: slug} = link ->
        update_post_field(slug, :link, link)

      _ ->
        :ignore
    end)

    # TODO: redo this, do not generate separate content trees with different sort
    # orders for the same post set. Generate only once, respecting the post set
    # ordering configuration.

    ConCache.put(@index_cache_name, content_tree_key(:date), tree)
    tree
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

  # TODO: For the initial purpose of this project, this solution is ok,
  # but eventually let's implement it with a "real" tree or linked list.
  defp do_build_taxonomy_tree(with_home \\ false) do
    get_all_taxonomies()
    |> sort_by_slug()
    |> (fn
          [_home | tree] when not with_home -> tree
          tree -> tree
        end).()
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
    |> Enum.map(fn %Link{children: posts} = taxonomy ->
      taxonomy
      |> Map.put(:children, posts |> sort_by_published_date())
    end)
  end

  defp do_build_content_tree(tree) do
    with_home =
      Application.get_env(:live_markdown, LiveMarkdown.Content)[:content_tree_display_home]

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
    |> (fn
          [_home | tree] when not with_home -> tree
          tree -> tree
        end).()
    |> build_tree_navigation()
  end

  defp build_tree_navigation(tree) do
    tree
    |> Enum.with_index()
    |> Enum.map(fn
      {%Link{} = link, 0} ->
        Map.put(link, :next, Enum.at(tree, 1))

      {%Link{} = link, pos} ->
        link
        |> Map.put(:previous, Enum.at(tree, pos - 1))
        |> Map.put(:next, Enum.at(tree, pos + 1))
    end)
  end

  defp level_for_joined_post(parent_slug, parent_level) when parent_slug == "/",
    do: parent_level

  defp level_for_joined_post(_, parent_level), do: parent_level + 1

  defp slug_key(slug), do: {:slug, slug}
  defp taxonomy_tree_key(sort_posts_by), do: {:taxonomy_tree, sort_posts_by}

  defp content_tree_key(sort_posts_by),
    do: {:content_tree, sort_posts_by}
end
