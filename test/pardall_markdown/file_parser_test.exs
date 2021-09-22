defmodule PardallMarkdown.FileParserTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.FileParser
  alias PardallMarkdown.Content.Post

  setup do
    Application.ensure_all_started(:pardall_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(100)

    current_config = Application.get_env(:pardall_markdown, PardallMarkdown.Content)
    |> Keyword.merge([root_path: "./test"])

    [current_config: current_config]
  end

  @tag :file_parser
  test "file without metadata is correctly parsed", %{current_config: current_config} do
    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [is_markdown_metadata_required: false])
    )

    {:ok, %Post{}} = FileParser.extract!("./test/individual_content/no_metadata.md")

    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [is_markdown_metadata_required: true])
    )

    {:error, "could not find separator --- in \"./test/individual_content/no_metadata.md\""} = FileParser.extract!("./test/individual_content/no_metadata.md")
  end

  @tag :file_parser
  test "publishing status correctly set depending on the configuration", %{current_config: current_config} do
    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [is_content_draft_by_default: true])
    )

    {:ok, %Post{is_published: true}} = FileParser.extract!("./test/individual_content/set_published.md")
    {:ok, %Post{is_published: false}} = FileParser.extract!("./test/individual_content/dont_set_published.md")
    {:ok, %Post{is_published: false}} = FileParser.extract!("./test/individual_content/set_unpublished.md")

    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [is_content_draft_by_default: false])
    )

    # No changes
    {:ok, %Post{is_published: true}} = FileParser.extract!("./test/individual_content/set_published.md")
    # Since the config has changed, the post is now published by default
    {:ok, %Post{is_published: true}} = FileParser.extract!("./test/individual_content/dont_set_published.md")
    # No changes
    {:ok, %Post{is_published: false}} = FileParser.extract!("./test/individual_content/set_unpublished.md")
  end
end
