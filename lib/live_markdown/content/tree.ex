defmodule LiveMarkdown.Content.Tree do
  alias LiveMarkdown.{Post, Link}
  import LiveMarkdown.Content.Utils
  import LiveMarkdown.Content.Filters

  # TODO: For the initial purpose of this project, this solution is ok,
  # but eventually let's implement it with a "real" tree or linked list.
  def build_taxonomy_tree(links, with_home \\ false) when is_list(links) do
    links
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

  def build_content_tree(tree) when is_list(tree) do
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
