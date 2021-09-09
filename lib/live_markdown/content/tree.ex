defmodule LiveMarkdown.Content.Tree do
  alias LiveMarkdown.{Post, Link}
  import LiveMarkdown.Content.Utils
  import LiveMarkdown.Content.Filters

  @doc """
  Splits a path into a tree of categories, containing both readable category names
  and slugs for all categories in the hierarchy. The categories list is indexed from the
  topmost to the lowermost in the hiearchy, example: Games > PC > RPG.

  Also returns the level in the tree in which the category can be found,
  as well as all parent categories slugs recursively, where `level: 0` is
  for root pages (i.e. no category).

  TODO: For the initial purpose of this project, this solution is ok,
  but eventually let's implement it with a "real" tree or linked list.

  ## Examples

      iex> LiveMarkdown.Content.Utils.extract_categories_from_path("/blog/art/3d-models/post.md")
      [
        %{title: "Blog", slug: "/blog", level: 0, parents: ["/"]},
        %{
          title: "Art",
          slug: "/blog/art",
          level: 1,
          parents: ["/", "/blog"]
        },
        %{
          title: "3D Models",
          slug: "/blog/art/3d-models",
          level: 2,
          parents: ["/", "/blog", "/blog/art"]
        }
      ]

      iex> LiveMarkdown.Content.Utils.extract_categories_from_path("/blog/post.md")
      [%{title: "Blog", slug: "/blog", level: 0, parents: ["/"]}]

      iex> LiveMarkdown.Content.Utils.extract_categories_from_path("/post.md")
      [%{title: "Home", slug: "/", level: 0, parents: ["/"]}]
  """
  def extract_categories_from_path(full_path) do
    full_path
    |> String.replace(Path.basename(full_path), "")
    |> do_extract_categories()
  end

  # Root / Page
  defp do_extract_categories("/"), do: [%{title: "Home", slug: "/", level: 0, parents: ["/"]}]
  # Path with category and possibly, hierarchy
  defp do_extract_categories(path) do
    final_slug = extract_slug_from_path(path)
    slug_parts = final_slug |> String.split("/")

    path
    |> String.replace(~r/^\/(.*)\/$/, "\\1")
    |> String.split("/")
    |> Enum.with_index()
    |> Enum.map(fn {part, pos} ->
      slug =
        slug_parts
        |> Enum.take(pos + 2)
        |> Enum.join("/")

      parents =
        for idx <- 0..pos do
          slug_parts |> Enum.take(idx + 1) |> Enum.join("/")
        end
        |> Enum.map(fn
          "" -> "/"
          parent -> parent
        end)

      category = part |> capitalize_as_taxonomy_name()

      %{title: category, slug: slug, level: pos, parents: parents}
    end)
  end

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
    |> sort_taxonomy_tree_taxonomies()
  end

  # Warning: highly inefficient implementation for now (roughly O(n!) or O(n^4)),
  # but it fits the purpose, considering the content rebuilding process
  # is performed as a rarely recurring background tasks.
  defp sort_taxonomy_tree_taxonomies(tree) when is_list(tree) do
    taxonomies_with_post_sorting = tree |> get_taxonomies_with_custom_post_sorting()
    taxonomies_with_sorting = tree |> get_taxonomies_with_custom_sorting()

    nest_children_taxonomies_into_root_taxonomies(
      tree,
      {:for_posts, taxonomies_with_post_sorting, :for_taxonomies, taxonomies_with_sorting}
    )
  end

  # defp do_sort_taxonomy_tree_taxonomies(
  #        [%{children_links: links, parents: parents} = link | tail],
  #        taxonomies_with_sorting
  #      ) do
  # end

  defp nest_children_taxonomies_into_root_taxonomies(tree, taxonomies_with_sorting) do
    main_tree_by_slug =
      Enum.reduce(tree, %{}, fn
        %Link{slug: slug} = link, acc -> Map.put(acc, slug, link)
      end)

    tree
    |> Enum.reduce(%{}, fn
      %Link{parents: parents, type: :taxonomy} = link, acc ->
        acc
        |> Map.update(parents, [link], fn links ->
          links ++ [link]
        end)
    end)
    |> Enum.reduce(%{}, fn {parent_slugs, children}, acc_tree ->
      case nest_children_links(
             main_tree_by_slug,
             acc_tree,
             taxonomies_with_sorting,
             parent_slugs,
             children
           ) do
        # Root level, no updates made
        links when is_list(links) ->
          Enum.reduce(links, acc_tree, fn %{slug: slug} = link, acc ->
            Map.put(acc, slug, link)
          end)

        %Link{slug: final_slug} = link ->
          Map.put(acc_tree, final_slug, link)
      end
    end)
    |> Map.values()
  end

  # Recursively nest children taxonomies into their innermost parent
  # taxonomy `Link.children_links`. The result must be per each root taxonomy,
  # a taxonomy `%Link{}` with all nested children (and each nest children
  # contain their own children recursively).
  defp nest_children_links(
         main_tree,
         updated_tree,
         taxonomies_with_sorting,
         parent_slugs,
         links,
         previous_parents \\ nil
       )

  defp nest_children_links(
         main_tree,
         updated_tree,
         taxonomies_with_sorting,
         ["/" | parents],
         links,
         previous_parents
       ) do
    nest_children_links(
      main_tree,
      updated_tree,
      taxonomies_with_sorting,
      parents,
      links,
      previous_parents
    )
  end

  defp nest_children_links(
         main_tree,
         updated_tree,
         taxonomies_with_sorting,
         [parent_slug | parents],
         links,
         nil
       ) do
    parent = Map.get(updated_tree, parent_slug) || Map.get(main_tree, parent_slug)

    nest_children_links(main_tree, updated_tree, taxonomies_with_sorting, parents, links, [parent])
  end

  defp nest_children_links(
         main_tree,
         updated_tree,
         taxonomies_with_sorting,
         [parent_slug | parents],
         links,
         [previous_parent | _] = previous_parents
       ) do
    parent =
      Enum.find(previous_parent.children_links, fn
        %{slug: slug} -> slug == parent_slug
        _ -> false
      end)
      |> case do
        nil ->
          Map.get(updated_tree, parent_slug) || Map.get(main_tree, parent_slug)

        parent ->
          parent
      end

    nest_children_links(
      main_tree,
      updated_tree,
      taxonomies_with_sorting,
      parents,
      links,
      previous_parents ++ [parent]
    )
  end

  # Final destination
  defp nest_children_links(_, _, taxonomies_with_sorting, [], links, [_ | _] = all_parents) do
    [first | all] = all_parents |> Enum.reverse()

    final_link =
      put_children_links_into_parent_link_and_sort(
        first,
        links,
        taxonomies_with_sorting
      )

    put_parent_links_recursively(all, final_link, taxonomies_with_sorting)
  end

  # Call made with level 1 links and no nesting, return without any processing
  defp nest_children_links(_, _, _, _, links, _), do: links

  defp put_parent_links_recursively([parent | previous_parents], link, taxonomies_with_sorting) do
    final_link =
      put_children_links_into_parent_link_and_sort(parent, link, taxonomies_with_sorting)

    put_parent_links_recursively(previous_parents, final_link, taxonomies_with_sorting)
  end

  defp put_parent_links_recursively([], link, _), do: link

  defp put_children_links_into_parent_link_and_sort(
         %Link{
           children_links: current_children,
           children: posts,
           parents: parent_slugs,
           slug: slug
         } = parent,
         links,
         {:for_posts, taxonomies_with_post_sorting, :for_taxonomies, taxonomies_with_sorting}
       )
       when is_list(links) do
    current_children =
      current_children
      |> Enum.filter(fn %Link{slug: child_slug} ->
        is_nil(Enum.find(links, fn %Link{slug: find_slug} -> child_slug == find_slug end))
      end)

    {:sort_by, sort_by, :sort_order, sort_order} =
      (parent_slugs ++ [slug])
      |> Enum.reverse()
      |> find_sorting_method_for_taxonomies(taxonomies_with_sorting)

    children =
      (current_children ++ links)
      |> sort_by_custom(sort_by, sort_order)

    parent
    |> Map.put(
      :children,
      posts |> sort_posts_by_closest_sorting_method(parent, taxonomies_with_post_sorting)
    )
    |> Map.put(:children_links, children)
  end

  defp put_children_links_into_parent_link_and_sort(
         %Link{} = parent,
         %Link{} = link,
         taxonomies_with_sorting
       ),
       do: put_children_links_into_parent_link_and_sort(parent, [link], taxonomies_with_sorting)

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
      |> find_sorting_method_for_posts(taxonomies_with_sorting)

    posts
    |> sort_by_custom(sort_by, sort_order)
  end

  defp sort_posts_by_closest_sorting_method([], _, _), do: []

  defp find_sorting_method_for_posts(post_taxonomies, taxonomies_with_sorting) do
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

  defp find_sorting_method_for_taxonomies(parent_slugs, taxonomies_with_sorting) do
    # O(n^2)
    taxonomies_with_sorting
    |> Enum.find(fn
      %Link{
        slug: tax_slug,
        type: :taxonomy,
        index_post: %Post{
          metadata: %{sort_taxonomies_by: sort_by, sort_taxonomies_order: sort_order}
        }
      }
      when not is_nil(sort_by) and not is_nil(sort_order) ->
        parent_slugs
        |> Enum.find(fn slug -> tax_slug == slug end)

      _ ->
        false
    end)
    |> case do
      nil ->
        {:sort_by, default_taxonomy_sort_by(), :sort_order, default_taxonomy_sort_order()}

      %Link{
        index_post: %Post{
          metadata: %{sort_taxonomies_by: sort_by, sort_taxonomies_order: sort_order}
        }
      } ->
        {:sort_by, sort_by, :sort_order, sort_order}
    end
  end

  defp get_taxonomies_with_custom_post_sorting(taxonomies, filtered \\ [])

  defp get_taxonomies_with_custom_post_sorting(
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
       do: get_taxonomies_with_custom_post_sorting(tail, filtered ++ [taxonomy])

  defp get_taxonomies_with_custom_post_sorting([_ | tail], filtered),
    do: get_taxonomies_with_custom_post_sorting(tail, filtered)

  defp get_taxonomies_with_custom_post_sorting([], filtered), do: filtered

  defp get_taxonomies_with_custom_sorting(taxonomies, filtered \\ [])

  defp get_taxonomies_with_custom_sorting(
         [
           %Link{
             type: :taxonomy,
             index_post: %Post{
               metadata: %{sort_taxonomies_by: sort_by, sort_taxonomies_order: sort_order}
             }
           } = taxonomy
           | tail
         ],
         filtered
       )
       when not is_nil(sort_by) and not is_nil(sort_order),
       do: get_taxonomies_with_custom_sorting(tail, filtered ++ [taxonomy])

  defp get_taxonomies_with_custom_sorting([_ | tail], filtered),
    do: get_taxonomies_with_custom_sorting(tail, filtered)

  defp get_taxonomies_with_custom_sorting([], filtered), do: filtered

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
    raise "update with the new format with :children_links"

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
end
