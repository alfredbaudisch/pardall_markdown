defmodule LiveMarkdown.Content.Tree do
  alias LiveMarkdown.{Post, Link}
  import LiveMarkdown.Content.Utils
  import LiveMarkdown.Content.Filters

  @doc """
  Generates a tree of taxonomies, where each taxonomy gets
  inserted their direct children non-draft posts.
  - Posts are sorted by their innermost taxonomy sorting method.
  - Children taxonomy are added after their closest parent taxonomy,
    they are not nested in its parent taxonomy.

  ## Example

  Consider the following content structure:
  - Blog
    - root-post
    - News
      - post-1
      - post-2
  - Docs
    - introducion

  The taxonomy tree will be generated as (most fields omitted for readability):
  ```
  [
    %Link{slug: "/blog", title: "Blog", level: 1, children: [
      %Post{slug: "/blog/root-post"}
    ]},
    %Link{slug: "/blog/news", title: "News", level: 2, children: [
      %Post{slug: "/blog/news/post-1"},
      %Post{slug: "/blog/news/post-2"}
    ]},
    %Link{slug: "/docs", title: "Docs", level: 1, children: [
      %Post{slug: "/docs/introducion"}
    ]}
  ]
  ```
  """
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
            # where its parent is its innermost taxonomy.
            List.last(post_taxonomies).slug == slug

          _ ->
            true
        end)
        |> filter_by_is_published()

      taxonomy
      |> Map.put(:children, posts)
    end)
    |> sort_taxonomy_tree_posts()
  end

  @doc """
  Generates a content tree from an input taxonomy tree. The content
  tree is akin to a sitemap.

  Posts are moved out of the taxonomy `children` field and added to the
  main list as %Link of the type `:post`, positioned after their
  innermost parent taxonomy.

  ## Example

  Consider the following content structure:
  - Blog
    - root-post
    - News
      - post-1
      - post-2
  - Docs
    - introducion

  The content tree will be generated as (most fields omitted for readability):
  ```
  [
    %Link{slug: "/blog", title: "Blog", type: :taxonomy, level: 1},
    %Link{slug: "/blog/root-post", title: "Root Post", type: :post, level: 2},
    %Link{slug: "/blog/news", title: "News", type: :taxonomy, level: 2},
    %Link{slug: "/blog/news/post-1", title: "Post 1", type: :post, level: 3},
    %Link{slug: "/blog/news/post-2", title: "Post 2", type: :post, level: 3},
    %Link{slug: "/docs", title: "Docs", type: :taxonomy, level: 1},
    %Link{slug: "/docs/introducion", title: "Introducion", type: :post, level: 2}
  ]
  ```
  """
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

  defp sort_taxonomy_tree_posts(tree) when is_list(tree) do
    taxonomies_with_sorting = tree |> filter_taxonomies_with_custom_sorting()

    tree
    |> Enum.map(fn %Link{children: posts} = taxonomy ->
      taxonomy
      |> Map.put(
        :children,
        posts
        |> sort_posts_by_closest_sorting_method(taxonomy, taxonomies_with_sorting)
      )
    end)
  end

  defp sort_posts_by_closest_sorting_method(
         posts,
         %Link{
           type: :taxonomy,
           index_post: %Post{metadata: %{sort_by: sort_by, sort_order: sort_order}}
         },
         _taxonomies_with_sorting
       ) do
    posts
    |> sort_by_custom(sort_by, sort_order)
  end

  defp sort_posts_by_closest_sorting_method(
         [%Post{taxonomies: post_taxonomies} | _] = posts,
         %Link{level: max_level, type: :taxonomy},
         taxonomies_with_sorting
       ) do
    {:sort_by, sort_by, :sort_order, sort_order} =
      post_taxonomies
      |> Enum.reject(fn %Link{level: level} -> level > max_level end)
      |> Enum.reverse()
      |> find_sorting_method_from_taxonomies(taxonomies_with_sorting)

    posts
    |> sort_by_custom(sort_by, sort_order)
  end

  defp sort_posts_by_closest_sorting_method([], _, _), do: []

  defp find_sorting_method_from_taxonomies(post_taxonomies, taxonomies_with_sorting) do
    # O(n^2)
    taxonomies_with_sorting
    |> Enum.find(fn
      %Link{
        slug: tax_slug,
        type: :taxonomy,
        index_post: %Post{metadata: %{sort_by: sort_by, sort_order: sort_order}}
      }
      when not is_nil(sort_by) and not is_nil(sort_order) ->
        post_taxonomies
        |> Enum.find(fn %Link{slug: slug} ->
          tax_slug == slug
        end)

      _ ->
        false
    end)
    |> case do
      nil ->
        {:sort_by, default_sort_by(), :sort_order, default_sort_order()}

      %Link{index_post: %Post{metadata: %{sort_by: sort_by, sort_order: sort_order}}} ->
        {:sort_by, sort_by, :sort_order, sort_order}
    end
  end

  defp filter_taxonomies_with_custom_sorting(taxonomies, filtered \\ [])

  defp filter_taxonomies_with_custom_sorting(
         [
           %Link{
             type: :taxonomy,
             index_post: %Post{metadata: %{sort_by: sort_by, sort_order: sort_order}}
           } = taxonomy
           | tail
         ],
         filtered
       )
       when not is_nil(sort_by) and not is_nil(sort_order),
       do: filter_taxonomies_with_custom_sorting(tail, filtered ++ [taxonomy])

  defp filter_taxonomies_with_custom_sorting([_ | tail], filtered),
    do: filter_taxonomies_with_custom_sorting(tail, filtered)

  defp filter_taxonomies_with_custom_sorting([], filtered), do: filtered
end
