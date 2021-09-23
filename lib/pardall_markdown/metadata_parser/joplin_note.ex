defmodule PardallMarkdown.MetadataParser.JoplinNote do
  @behaviour PardallMarkdown.MetadataParser

  @default_metadata_parser PardallMarkdown.MetadataParser.ElixirMap

  @impl PardallMarkdown.MetadataParser
  def parse(path, contents, opts) do
    is_index? = Keyword.get(opts, :is_index?, false)

    joplin_config =
      Application.get_env(
        :pardall_markdown,
        PardallMarkdown.MetadataParser.JoplinNote
      ) || [metadata_parser_after_title: @default_metadata_parser]

    parser = Keyword.get(joplin_config, :metadata_parser_after_title, @default_metadata_parser)

    do_parse = fn split_contents ->
      apply(parser, :parse, [path, split_contents, opts])
    end

    case :binary.split(contents, ["\n\n", "\r\n\r\n"]) do
      [_] ->
        do_parse.(contents)

      [_, contents] when is_index? ->
        do_parse.(contents)

      [title, contents] ->
        case do_parse.(contents) do
          # A title from the metadata always has priority
          {:ok, %{title: custom_title}, _} = parsed
          when is_binary(custom_title) and custom_title != "" ->
            parsed

          # Use the title from the first line
          {:ok, attrs, body} ->
            {:ok, attrs |> Map.put(:title, title), body}

          other ->
            other
        end
    end
  end
end
