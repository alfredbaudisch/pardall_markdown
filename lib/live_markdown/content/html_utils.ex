defmodule LiveMarkdown.Content.HtmlUtils do
  def add_ids_and_anchors_to_headings(html) do
    {updated_tree, _} =
      Floki.parse_fragment!(html)
      |> Floki.traverse_and_update(%{}, fn
        {"h" <> level, attrs, children} = el, acc ->
          case find_node_text(children) do
            nil ->
              {el, acc}

            text ->
              id = Slug.slugify(text)
              count = Map.get(acc, id, "")
              attrs = [{"id", get_id_with_count(id, count)} | attrs]

              anchor =
                {"a",
                 [
                   {"href", "#" <> get_id_with_count(id, count)},
                   {"class", "anchor-link"},
                   {"data-title", text |> String.trim()}
                 ], []}

              {{"h" <> level, attrs, [anchor | children]},
               Map.put(acc, id, increase_id_count(count))}
          end

        el, acc ->
          {el, acc}
      end)

    updated_tree |> Floki.raw_html()
  end

  def strip_in_between_space(html),
    do:
      html
      |> String.replace("\n", "")
      |> String.trim()
      |> String.replace(~r/>\s+</, "><")

  # Find the header text
  defp find_node_text([child | children]) when is_binary(child) and child != "",
    do: if(String.match?(child, ~r/[<>]+/), do: find_node_text(children), else: child)

  defp find_node_text([_ | children]), do: find_node_text(children)
  defp find_node_text(_), do: nil

  defp get_id_with_count(id, ""), do: id
  defp get_id_with_count(id, count), do: "#{id}-#{count}"
  defp increase_id_count(""), do: 1
  defp increase_id_count(count), do: count + 1
end
