defmodule KodaMarkdown.Content.HtmlUtils do
  def generate_anchors_and_toc(html, %{slug: slug}) do
    {updated_tree, %{toc: toc}} =
      Floki.parse_fragment!(html)
      |> Floki.traverse_and_update(%{counters: %{}, toc: []}, fn
        {"h" <> level, attrs, children} = el, acc ->
          case find_node_text(children) do
            nil ->
              {el, acc}

            text ->
              id = Slug.slugify(text)
              count = Map.get(acc.counters, id, "")
              attrs = [{"id", get_id_with_count(id, count)} | attrs]

              title = text |> String.trim()
              link_id = "#" <> get_id_with_count(id, count)

              anchor =
                {"a",
                 [
                   {"href", link_id},
                   {"class", "anchor-link __koda-anchor-link"},
                   {"data-title", title}
                 ], []}

              toc_item = %{
                id: link_id,
                parent_slug: slug,
                title: title,
                level: get_level_for_toc(acc[:toc], level)
              }

              acc = put_in(acc[:counters][id], increase_id_count(count))
              acc = put_in(acc[:toc], acc.toc ++ [toc_item])

              {{"h" <> level, attrs, [anchor | children]}, acc}
          end

        el, acc ->
          {el, acc}
      end)

    {:ok, updated_tree |> Floki.raw_html(), toc}
  end

  defp get_level_for_toc([], _), do: 1
  defp get_level_for_toc(_, level), do: level |> String.to_integer()

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
