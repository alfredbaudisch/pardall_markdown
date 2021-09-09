defmodule LiveMarkdownWeb.ContentHelpers do
  alias LiveMarkdown.Link
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  @doc """
  Generates a HTML string of nested `<ul/>` lists of Taxonomies names,
  with LiveView links to the taxonomy slug.

  ## Example
  Input list of taxonomies:
  ```elixir
  [
    %LiveMarkdown.Link{level: 0, name: "Home", parents: ["/"], slug: "/"},
    %LiveMarkdown.Link{level: 0, name: "Blog", parents: ["/"], slug: "/blog"},
    %LiveMarkdown.Link{level: 1, name: "Art", parents: ["/", "/blog"], slug: "/blog/art"},
    %LiveMarkdown.Link{level: 2, name: "3D", parents: ["/", "/blog", "/blog/art"], slug: "/blog/art/3d"}
  ]
  ```

  The resulting HTML string:
  ```html
  <ul>
  <li><a data-phx-link="redirect" data-phx-link-state="push" href="/">Home</a></li>
  <li>
      <a data-phx-link="redirect" data-phx-link-state="push" href="/blog">Blog</a>
      <ul>
        <li>
            <a data-phx-link="redirect" data-phx-link-state="push" href="/blog/art">Art</a>
            <ul>
              <li><a data-phx-link="redirect" data-phx-link-state="push" href="/blog/art/3d">3D</a></li>
            </ul>
        </li>
      </ul>
  </li>
  </ul>
  ```
  """
  def taxonomy_tree_list(taxonomies) do
    taxonomy_tree(taxonomies)
  end

  defp taxonomy_tree(taxonomies, all \\ "<ul>", previous_level \\ -1)

  defp taxonomy_tree([%Link{level: level} = taxonomy | tail], all, -1) do
    taxonomy_tree(tail, all <> "<li>" <> live_link(taxonomy), level)
  end

  defp taxonomy_tree([%Link{level: level} = taxonomy | tail], all, previous_level)
       when level > previous_level do
    # nest new level
    taxonomy_tree(tail, all <> "<ul><li>" <> live_link(taxonomy), level)
  end

  defp taxonomy_tree([%Link{level: level} = taxonomy | tail], all, previous_level)
       when level < previous_level do
    # go up (previous_level - level) levels, closing nest(s)
    diff = previous_level - level
    close = String.duplicate("</ul></li>", diff)

    taxonomy_tree(tail, all <> close <> "<li>" <> live_link(taxonomy), level)
  end

  defp taxonomy_tree([%Link{level: level} = taxonomy | tail], all, previous_level)
       when level == previous_level do
    # same level
    taxonomy_tree(tail, all <> "</li><li>" <> live_link(taxonomy), level)
  end

  # Empty initial list provided
  defp taxonomy_tree([], "<ul>", _), do: ""

  # No more taxonomies to traverse, finish and return the list
  defp taxonomy_tree([], all, previous_level),
    do: all <> String.duplicate("</li></ul>", previous_level) <> "</li></ul>"

  def link_tree_list(links) do
    link_tree(links)
  end

  defp link_tree(links, all \\ "<ul>", previous_level \\ -1)

  defp link_tree([%Link{children_links: children} = link | tail], all, -1) do
    all = all <> "<li>" <> live_link(link)
    all_children = link_tree(children)
    link_tree(tail, all <> all_children, 1)
  end

  defp link_tree(
         [%Link{children_links: children} = link | tail],
         all,
         previous_level
       ) do
    all = all <> "</li><li>" <> live_link(link)
    all_children = link_tree(children)
    link_tree(tail, all <> all_children, previous_level)
  end

  defp link_tree([], "<ul>", _), do: ""
  defp link_tree([], all, _), do: all <> "</li></ul>"

  defp live_link(%Link{title: title, slug: slug}) do
    live_redirect(title, to: slug)
    |> safe_to_string()
  end
end
