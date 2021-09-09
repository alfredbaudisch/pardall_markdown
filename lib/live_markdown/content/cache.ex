defmodule LiveMarkdown.Content.Cache do
  require Logger
  alias LiveMarkdown.{Post, Link}
  import LiveMarkdown.Content.Utils
  import LiveMarkdown.Content.Filters

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
    tree = do_build_taxonomy_tree()
    ConCache.put(@index_cache_name, taxonomy_tree_key(), tree)
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
      %Link{type: :post, slug: slug} = link ->
        update_post_field(slug, :link, link)

      _ ->
        :ignore
    end)

    # TODO: redo this, do not generate separate content trees with different sort
    # orders for the same post set. Generate only once, respecting the post set
    # ordering configuration.

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

  # TODO: For the initial purpose of this project, this solution is ok,
  # but eventually let's implement it with a "real" tree or linked list.
  defp do_build_taxonomy_tree(with_home \\ false) do
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
      taxonomy
      |> Map.put(:children, posts |> sort_posts_by_closest_sorting_method(taxonomy))
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
            level: joined_post_level(taxonomy.slug, taxonomy.level),
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

  defp joined_post_level(parent_slug, parent_level) when parent_slug == "/",
    do: parent_level

  defp joined_post_level(_, parent_level), do: parent_level + 1

  defp slug_key(slug), do: {:slug, slug}
  defp taxonomy_tree_key, do: :taxonomy_tree
  defp content_tree_key, do: :content_tree

  defp sort_posts_by_closest_sorting_method(posts, %Link{
         type: :taxonomy,
         index_post: %Post{metadata: %{sort_by: sort_by, sort_order: sort_order}}
       }) do
    posts
    |> sort_by_custom(sort_by, sort_order)
  end

  defp sort_posts_by_closest_sorting_method(
         [%Post{taxonomies: taxonomies} | _] = posts,
         %Link{level: max_level}
       ) do
    {:sort_by, sort_by, :sort_order, sort_order} =
      taxonomies
      |> Enum.reject(fn %Link{level: level} -> level > max_level end)
      |> Enum.reverse()
      |> find_sorting_method_from_taxonomies()

    posts
    |> sort_by_custom(sort_by, sort_order)
  end

  defp sort_posts_by_closest_sorting_method([] = posts, _), do: posts

  defp find_sorting_method_from_taxonomies([
         %Link{
           type: :taxonomy,
           index_post: %Post{metadata: %{sort_by: sort_by, sort_order: sort_order}}
         }
         | _
       ]) do
    {:sort_by, sort_by, :sort_order, sort_order}
  end

  defp find_sorting_method_from_taxonomies([_ | tail]),
    do: find_sorting_method_from_taxonomies(tail)

  defp find_sorting_method_from_taxonomies([]),
    do: {:sort_by, default_sort_by(), :sort_order, default_sort_order()}
end
