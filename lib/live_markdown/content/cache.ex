defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.{Post, Link}
  alias LiveMarkdown.Content.Tree

  @cache_name Application.compile_env!(:live_markdown, [LiveMarkdown.Content, :cache_name])
  @index_cache_name Application.compile_env!(:live_markdown, [
                      LiveMarkdown.Content,
                      :index_cache_name
                    ])

  def get_by_slug(slug), do: ConCache.get(@cache_name, slug_key(slug))

  def get_all_posts(type \\ :all) do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.filter(fn
      {_, %Post{type: p_type}} -> type == :all or p_type == type
      _ -> false
    end)
    |> Enum.map(fn {_, %Post{} = post} -> post end)
  end

  def get_all_links(type \\ :all) do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.filter(fn
      {_, %Link{type: l_type}} -> type == :all or l_type == type
      _ -> false
    end)
    |> Enum.map(fn {_, %Link{} = link} -> link end)
  end

  def get_taxonomy_tree() do
    get = fn -> ConCache.get(@index_cache_name, taxonomy_tree_key()) end

    case get.() do
      nil ->
        build_taxonomy_tree()
        get.()

      tree ->
        tree
    end
  end

  def get_content_tree() do
    get = fn -> ConCache.get(@index_cache_name, content_tree_key()) end

    case get.() do
      nil ->
        build_content_tree()
        get.()

      tree ->
        tree
    end
  end

  def save_post(%Post{type: :index} = post) do
    save_post_taxonomies(post)
  end

  def save_post(%Post{} = post) do
    save_post_pure(post)
    save_post_taxonomies(post)
  end

  def save_post_pure(%Post{type: type, slug: slug} = post) when type != :index do
    key = slug_key(slug)
    ConCache.put(@cache_name, key, post)
  end

  def update_post_field(slug, field, value) do
    case get_by_slug(slug) do
      nil -> nil
      %Post{} = post -> post |> Map.put(field, value) |> save_post_pure()
    end
  end

  def build_taxonomy_tree() do
    tree = get_all_links() |> Tree.build_taxonomy_tree()

    # TODO: sort taxonomies by their closest sorting method

    ConCache.put(@index_cache_name, taxonomy_tree_key(), tree)
    tree
  end

  # Posts are extracted from the `children` field of a taxonomy
  # and added to the taxonomies list as a Link, while keeping
  # the correct nesting under their parent taxonomy,
  # the equivalent of a sitemap.
  def build_content_tree do
    tree =
      get_all_links()
      |> Tree.build_taxonomy_tree(true)
      |> Tree.build_content_tree()

    # Update each post in cache with their related link
    Enum.each(tree, fn
      %Link{type: :post, slug: slug} = link ->
        update_post_field(slug, :link, link)

      _ ->
        :ignore
    end)

    ConCache.put(@index_cache_name, content_tree_key(), tree)
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

  defp save_post_taxonomies(%Post{type: :index, taxonomies: taxonomies} = post) do
    taxonomies
    |> List.last()
    |> upsert_taxonomy_appending_post(post)
  end

  defp save_post_taxonomies(%Post{taxonomies: taxonomies} = post) do
    taxonomies
    |> Enum.map(&upsert_taxonomy_appending_post(&1, post))
  end

  defp upsert_taxonomy_appending_post(
         %Link{slug: slug} = taxonomy,
         %Post{type: :index, position: position, title: post_title} = post
       ) do
    do_update = fn taxonomy ->
      {:ok,
       %Link{
         taxonomy
         | index_post: post,
           position: position,
           title: post_title
       }}
    end

    ConCache.update(@cache_name, slug_key(slug), fn
      nil ->
        do_update.(taxonomy)

      %Link{} = taxonomy ->
        do_update.(taxonomy)
    end)
  end

  defp upsert_taxonomy_appending_post(
         %Link{slug: slug, children: children} = taxonomy,
         %Post{} = post
       ) do
    do_update = fn taxonomy, children ->
      {:ok, %{taxonomy | children: children ++ [Map.put(post, :content, nil)]}}
    end

    ConCache.update(@cache_name, slug_key(slug), fn
      nil ->
        do_update.(taxonomy, children)

      %Link{children: children} = taxonomy ->
        do_update.(taxonomy, children)
    end)
  end

  defp slug_key(slug), do: {:slug, slug}
  defp taxonomy_tree_key, do: :taxonomy_tree
  defp content_tree_key, do: :content_tree
end
