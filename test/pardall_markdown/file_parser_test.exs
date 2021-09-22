defmodule PardallMarkdown.FileParserTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.FileParser
  alias PardallMarkdown.Content.Post

  @moduletag :file_parser

  setup do
    Application.ensure_all_started(:pardall_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(100)

    current_config = Application.get_env(:pardall_markdown, PardallMarkdown.Content)
    |> Keyword.merge([root_path: "./test"])

    [current_config: current_config]
  end

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

  @tag :joplin
  test "first line is title (Joplin)", %{current_config: current_config} do
    Application.put_env(:pardall_markdown, PardallMarkdown.Content,
      Keyword.merge(current_config, [
        should_try_split_content_title_from_first_line: true,
        is_markdown_metadata_required: false,
        is_content_draft_by_default: false
      ])
    )

    {:ok, %Post{title: "This is the post title"}} = FileParser.extract!("./test/individual_content/joplin/post_title.md")

    {:ok, %Post{title: "Overriden title", content: "<p>\nContent should be here!</p>"}} = FileParser.extract!("./test/individual_content/joplin/post_title_overriden.md")

    {:ok, %Post{title: "This should work even without the top title", content: "<p>\nContent should be here?</p>"}} = FileParser.extract!("./test/individual_content/joplin/no_title_at_top.md")
  end

  test "override slug" do
    {:ok, post} = FileParser.extract!("./test/individual_content/custom_slug.md")
    assert post.slug == "/individual-content/my-slug"
    assert post.title == "Custom slug"
  end
end
