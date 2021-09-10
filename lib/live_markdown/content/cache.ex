defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.{Post, Link}
  import LiveMarkdown.Content.Filters
  import LiveMarkdown.Content.Utils

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

  def get_taxonomy_tree do
    get = fn -> ConCache.get(@index_cache_name, taxonomy_tree_key()) end

    case get.() do
      nil ->
        build_taxonomy_tree()
        get.()

      tree ->
        tree
    end
  end

  def get_content_tree(slug \\ "/") do
    get = fn -> ConCache.get(@index_cache_name, content_tree_key(slug)) end

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

  def save_post_pure(%Post{slug: _slug} = post) do
    save_slug(post)
  end

  def update_post_field(slug, field, value) do
    case get_by_slug(slug) do
      nil -> nil
      %Post{} = post -> post |> Map.put(field, value) |> save_post_pure()
    end
  end

  def save_slug(%{slug: slug} = item) do
    key = slug_key(slug)
    ConCache.put(@cache_name, key, item)
  end

  def build_taxonomy_tree() do
    tree = do_build_taxonomy_tree()
    ConCache.put(@index_cache_name, taxonomy_tree_key(), tree)
    tree
  end

  @doc """
  Posts are extracted from the `children` field of a taxonomy
  and added to the taxonomies list as a Link, while keeping
  the correct nesting under their parent taxonomy.

  Posts are also sorted accordingly to their topmost taxonomy
  sorting configuration.
  """
  def build_content_tree do
    tree =
      do_build_taxonomy_tree(true)
      |> do_build_content_tree()

    # Embed each post `%Link{}` into their individual `%Post{}` entities
    # Notice: this currently breaks the logic of sorting by title or by date,
    # since the links from "by_date" are inserted into the posts.
    Enum.each(tree, fn
      %Link{type: :post, slug: slug} = link ->
        update_post_field(slug, :link, link)

      _ ->
        :ignore
    end)

    ConCache.put(@index_cache_name, content_tree_key(), tree)

    # Split each root slug and its nested children and
    # save the roots independently.
    tree
    |> Enum.reduce(%{}, fn
      # Only root taxonomies, and ignore pages
      # (pages are posts in the root, but a link of type :post)
      %{type: :taxonomy, slug: slug, level: 0} = link, acc when slug != "/" ->
        Map.put(acc, slug, %{link: link, children: []})

      %{parents: [_ | [root_parent | _]]} = link, acc ->
        children = Map.get(acc, root_parent)[:children]
        put_in(acc[root_parent][:children], children ++ [link])

      # Ignore the very root link "/" and pages
      _, acc ->
        acc
    end)
    |> Enum.each(fn {root_slug, %{children: children}} ->
      ConCache.put(@index_cache_name, content_tree_key(root_slug), children)
    end)

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
         %Post{type: :index, position: position, title: post_title, metadata: metadata} = post
       ) do
    do_update = fn taxonomy ->
      {:ok,
       %{
         taxonomy
         | index_post: post,
           position: position,
           title: post_title,
           sort_by: Map.get(metadata, :sort_by, default_sort_by()) |> maybe_to_atom(),
           sort_order: Map.get(metadata, :sort_order, default_sort_order()) |> maybe_to_atom()
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

  defp get_taxonomy_sorting_methods_from_topmost_taxonomies do
    get_all_links()
    |> sort_by_slug()
    |> Enum.reduce(%{}, fn
      %Link{
        type: :taxonomy,
        level: 0,
        sort_by: sort_by,
        sort_order: sort_order,
        slug: slug
      },
      acc ->
        Map.put(acc, slug, {sort_by, sort_order})

      _, acc ->
        acc
    end)
  end

  defp do_build_taxonomy_tree(with_home \\ false) do
    sorting_methods = get_taxonomy_sorting_methods_from_topmost_taxonomies()

    get_all_links()
    |> sort_by_slug()
    |> (fn
          [%Link{slug: "/"} | tree] when not with_home -> tree
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
      {sort_by, sort_order} = find_sorting_method_for_taxonomy(taxonomy, sorting_methods)

      taxonomy
      |> Map.put(:children, posts |> sort_by_custom(sort_by, sort_order))
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
            type: :post,
            position: post.position
          }
        end)
      )
    end)
    |> (fn
          [%Link{slug: "/"} | tree] when not with_home ->
            tree

          tree ->
            tree
        end).()
    |> sort_taxonomies_embedded_posts()
    |> build_tree_navigation()
  end

  defp build_tree_navigation(tree) do
    total = Enum.count(tree)

    indexed =
      tree
      |> Enum.with_index()

    indexed
    |> Enum.map(fn
      {%Link{} = link, 0} ->
        next =
          case find_next_post(indexed, 0) do
            {next, _} -> next
            _ -> nil
          end

        Map.put(link, :next, next)

      {%Link{} = link, pos} when pos == total - 1 ->
        previous =
          case find_previous_post(indexed, pos) do
            {previous, _} -> previous
            _ -> nil
          end

        link
        |> Map.put(:previous, previous)

      {%Link{} = link, pos} ->
        previous =
          case find_previous_post(indexed, pos) do
            {previous, _} -> previous
            _ -> nil
          end

        next =
          case find_next_post(indexed, pos) do
            {next, _} -> next
            _ -> nil
          end

        link
        |> Map.put(:previous, previous)
        |> Map.put(:next, next)
    end)
  end

  defp find_previous_post(all_indexed, before_index) do
    all_indexed
    |> Enum.reverse()
    |> Enum.find(fn
      {%Link{type: :post}, pos} when pos < before_index -> true
      {_, _} -> false
    end)
  end

  defp find_next_post(all_indexed, after_index) do
    all_indexed
    |> Enum.find(fn
      {%Link{type: :post}, pos} when pos > after_index -> true
      {_, _} -> false
    end)
  end

  defp level_for_joined_post(parent_slug, parent_level) when parent_slug == "/",
    do: parent_level

  defp level_for_joined_post(_, parent_level), do: parent_level + 1

  defp sort_taxonomies_embedded_posts(tree) do
    taxonomies = get_all_links(:taxonomy)
    sorting_methods = get_taxonomy_sorting_methods_from_topmost_taxonomies()

    taxonomies
    |> Enum.map(fn
      %Link{type: :taxonomy, children: posts} = taxonomy ->
        {sort_by, sort_order} = find_sorting_method_for_taxonomy(taxonomy, sorting_methods)

        taxonomy
        |> Map.put(:children, posts |> sort_by_custom(sort_by, sort_order))
        |> save_slug()
    end)

    tree
  end

  defp find_sorting_method_for_taxonomy(
         %Link{parents: parents, slug: slug, level: level},
         sorting_methods
       ) do
    target_sort_taxonomy =
      cond do
        level == 0 and slug != "/" -> slug
        level == 0 -> "/"
        true -> Enum.at(parents, 1)
      end

    sorting_methods[target_sort_taxonomy]
  end

  defp slug_key(slug), do: {:slug, slug}
  defp taxonomy_tree_key(slug \\ "/"), do: {:taxonomy_tree, slug}

  defp content_tree_key(slug \\ "/"),
    do: {:content_tree, slug}
end
