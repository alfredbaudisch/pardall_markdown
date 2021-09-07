defmodule LiveMarkdownWeb.ContentHelpers do
  alias LiveMarkdown.Taxonomy
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers

  def generate_taxonomy_tree(taxonomies) do
    taxonomy_tree(taxonomies)
  end

  defp taxonomy_tree(taxonomies, all \\ "<ul>", previous_level \\ -1)

  defp taxonomy_tree([%{level: level} = taxonomy | tail], all, -1) do
    taxonomy_tree(tail, all <> "<li>" <> taxonomy_link(taxonomy), level)
  end

  defp taxonomy_tree([%{level: level} = taxonomy | tail], all, previous_level)
       when level > previous_level do
    # nest new level
    taxonomy_tree(tail, all <> "<ul><li>" <> taxonomy_link(taxonomy), level)
  end

  defp taxonomy_tree([%{level: level} = taxonomy | tail], all, previous_level)
       when level < previous_level do
    # go up (previous_level - level) levels, closing nest(s)
    diff = previous_level - level
    close = String.duplicate("</ul></li>", diff)

    taxonomy_tree(tail, all <> close <> "<li>" <> taxonomy_link(taxonomy), level)
  end

  defp taxonomy_tree([%{level: level} = taxonomy | tail], all, previous_level)
       when level == previous_level do
    # same level
    taxonomy_tree(tail, all <> "</li><li>" <> taxonomy_link(taxonomy), level)
  end

  defp taxonomy_tree([], all, previous_level),
    do: all <> String.duplicate("</li></ul>", previous_level) <> "</li></ul>"

  defp taxonomy_link(%Taxonomy{name: name, slug: slug}) do
    live_redirect(name, to: slug)
    |> safe_to_string()
  end
end
