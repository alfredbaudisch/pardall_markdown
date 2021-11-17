defmodule PardallMarkdown.MetadataParser.Yaml do
  import YamlElixir, only: [read_from_string: 2]
  @behaviour PardallMarkdown.MetadataParser

  @default_metadata_parser PardallMarkdown.MetadataParser.ElixirMap

  def parse(path, contents, opts) do
    is_index? = Keyword.get(opts, :is_index?, false)

    yaml_config =
      Application.get_env(
        :pardall_markdown,
        PardallMarkdown.MetadataParser.Yaml
      ) || [metadata_parser_after_title: @default_metadata_parser]

    parser = Keyword.get(yaml_config, :metadata_parser_after_title, @default_metadata_parser)

    do_parse = fn split_contents ->
      apply(parser, :parse, [path, split_contents, opts])
    end

    # REVIEW: Matches pattern used in ElixirMap
    # Perhaps there is a better patter to split on that won't
    # run interference to the parsing after the metadata?
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] ->
        do_parse.(contents)

      [_, contents] when is_index? ->
        do_parse.(contents)

      [yaml_string, contents] ->
        case read_from_string(yaml_string, atoms: true) do
          {:ok, frontmatter} ->
            # REVIEW: I get a nastygram if I don't prefix with \n---\n from ElixirMap.
            case do_parse.("\n---\n#{contents}") do
              {:ok, _attrs, body} ->
                # REVIEW: Represents [code, body] in ElixirMap
                {:ok, frontmatter, body}

              other ->
                other
            end

          other ->
            {:error,
             "oops, I don't think you have YAML present or you reached for the wrong parser: #{inspect(other)}"}
        end
    end
  end
end
