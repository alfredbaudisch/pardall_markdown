defmodule PardallMarkdown.FileParserTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.FileParser
  alias PardallMarkdown.Content.Post

  setup do
    Application.ensure_all_started(:pardall_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(100)
  end

  @tag :file_parser
  test "file without metadata is correctly parsed" do
    current_config =
      Application.get_env(:pardall_markdown, PardallMarkdown.Content)
      |> Keyword.merge([root_path: "./test"])

    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [is_markdown_metadata_required: false])
    )

    {:ok, %Post{}} = FileParser.extract!("./test/individual_content/no_metadata.md")

    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [is_markdown_metadata_required: true])
    )

    {:error, "could not find separator --- in \"./test/individual_content/no_metadata.md\""} = FileParser.extract!("./test/individual_content/no_metadata.md")
  end
end
