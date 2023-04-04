defmodule PardallMarkdown.Content.HtmlUtils do
  alias PardallMarkdown.Content.Utils

  def generate_summary_from_html(html, expected_length \\ 157)
  def generate_summary_from_html(html, _) when html == nil or html == "", do: nil

  @doc """
  Extract text from paragraphs `</p>` of a HTML `html` string,
  and assemble a string up until it reaches `expected_length` length.

  If the generated string length matches `expected_length`, an ellipsis
  will be appended to it. If the generated string is smaller than `expected_length`,
  then no ellipsis is added.

  If no text could be extracted from the input html, returns nil.

  ## Examples

      iex> PardallMarkdown.Content.HtmlUtils.generate_summary_from_html("<h1>Post Title</h1><main><article><div><p>So, <a href='link'>a description</a> will be generated from it. Even a <span>nested span</span>.</p></div></article></main><p>As you can see, this a long paragraph outside.</p>This is <a name='anchor'>an anchor</a>.")
      "So, a description will be generated from it. Even a nested span. As you can see, this a long paragraph outside."

      iex> PardallMarkdown.Content.HtmlUtils.generate_summary_from_html("<h1>Post Title</h1><main><article><div><p>So, <a href='link'>a description</a> will be generated from it. Even a <span>nested span</span>.</p><p>Another paragraph?</p><p>Another paragraph 2?</p><p>Another paragraph 3?</p><p>As you can see, this a very long paragraph. As you can see, this a very long paragraph.</p></div></article></main>")
      "So, a description will be generated from it. Even a nested span. Another paragraph? Another paragraph 2? Another paragraph 3? As you can see, this a very long..."
  """
  def generate_summary_from_html(html, expected_length) do
    document = Floki.parse_fragment!(html)

    Floki.find(document, "p")
    |> Enum.reduce("", fn
      {"p", _, children}, "" ->
        truncate(String.trim(children |> Floki.text()), expected_length)

      {"p", _, children}, final ->
        if String.length(final) < expected_length do
          truncate(final <> " " <> String.trim(children |> Floki.text()), expected_length)
        else
          final
        end

      _, final -> final
    end)
    |> trim_and_maybe_ellipsis(expected_length)
  end

  defp truncate(string, length) do
    if String.length(string) <= length do
      string
    else
      String.slice(string, 0..length)
    end
  end

  defp trim_and_maybe_ellipsis(string, _)
  when string == "" or is_nil(string), do: nil
  defp trim_and_maybe_ellipsis(string, expected_length) do
    string = String.trim(string)
    if String.length(string) < expected_length,
    do: string, else: string <> "..."
  end

  def convert_internal_links_to_live_links(html) do
    {updated_tree, _} =
      Floki.parse_fragment!(html)
      |> Floki.traverse_and_update(:ok, fn
        {"a", attrs, children} = el, acc ->
          with link when not is_nil(link) <- find_attr_href(attrs),
               true <- is_link_internal?(link) do
            # Remove current class and href because they are updated below
            filtered_attrs =
              attrs
              |> Enum.reject(fn {attr, _} -> attr == "href" end)

            attrs = [
              {"data-phx-link", "redirect"},
              {"data-phx-link-state", "push"},
              {"href", link |> Utils.slugify(["/", "./", "../"])}
              | filtered_attrs
            ]

            {{"a", attrs, children}, acc}
          else
            _ -> {el, acc}
          end

        el, acc ->
          {el, acc}
      end)

    {:ok, updated_tree |> Floki.raw_html()}
  end

  defp find_attr_href([{"href", href} | _]), do: href
  defp find_attr_href([_ | tail]), do: find_attr_href(tail)
  defp find_attr_href(_), do: nil

  defp is_link_internal?(link),
    do:
      not (String.match?(link, ~r/^[a-zA-Z0-9]*:(\/\/)?[^\s]*/) or
             String.starts_with?(link, "#"))

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
                   {"class", "anchor-link __pardall-anchor-link"},
                   {"data-title", title}
                 ], []}

              toc_item = %{
                id: link_id,
                parent_slug: slug,
                title: title,
                level: get_level_for_toc(acc[:toc], level)
              }

              # toc_link = %TOC.Link{
              #   id: link_id,
              #   header: int_header_level,
              #   parent_slug: slug,
              #   title: title
              # }

              acc = put_in(acc[:counters][id], increase_id_count(count))
              # acc = put_in(acc[:toc_links], acc.toc_links ++ [toc_link])
              acc = put_in(acc[:toc], acc.toc ++ [link])
              acc = put_in(acc[:toc_positions], positions)

              {{"h" <> header_level, attrs, [anchor | children]}, acc}
          end

        el, acc ->
          {el, acc}
      end)

    # toc = TOC.generate(toc_links)
    # toc = toc |> PardallMarkdown.Utils.StructUtils.struct_to_map()

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
