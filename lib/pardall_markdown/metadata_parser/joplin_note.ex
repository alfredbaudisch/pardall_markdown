defmodule PardallMarkdown.MetadataParser.JoplinNote do
  @behaviour PardallMarkdown.MetadataParser

  alias PardallMarkdown.MetadataParser

  @impl PardallMarkdown.MetadataParser
  def parse(path, contents, opts) do
    is_index? = Keyword.get(opts, :is_index?, false)

    case :binary.split(contents, ["\n\n", "\r\n\r\n"]) do
      [_] ->
        MetadataParser.ElixirMap.parse(path, contents, opts)

      [_, contents] when is_index? ->
        MetadataParser.ElixirMap.parse(path, contents, opts)

      [title, contents] ->
        case MetadataParser.ElixirMap.parse(path, contents, opts) do
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
