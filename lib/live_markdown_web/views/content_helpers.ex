defmodule LiveMarkdownWeb.ContentHelpers do
  alias LiveMarkdown.Link
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  @doc """
  Generates a HTML string of nested `<ul/>` lists of Taxonomies and Post names,
  with LiveView links to the node slug.

  If the tree is a content tree, children posts will also be nested in the list.

  ## Example
  Resulting HTML string from an input taxonomy tree:
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
  def link_tree_list(links) do
    link_tree(links)
  end

  defp link_tree(links, all \\ "<ul>", previous_level \\ -1)

  defp link_tree(%Link{} = link, all, previous_level), do: link_tree([link], all, previous_level)

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
