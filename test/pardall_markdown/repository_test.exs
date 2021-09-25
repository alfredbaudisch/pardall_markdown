defmodule PardallMarkdown.RepositoryTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.Repository

  setup do
    Application.ensure_all_started(:pardall_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(300)
  end

  @tag :post_summary
  test "custom post summary and generated post summary" do
    # Custom
    post = Repository.get_by_slug!("/blog/dailies/first-day")
    assert post.summary == "Custom post summary"

    # Generated
    post = Repository.get_by_slug!("/blog/dailies/3d/blender/default-cube-not-deleted")
    assert post.summary == "Do not delete the Default Cube!"
  end

  # still not accounting for per-folder indexing
  test "content tree previous and next links" do
    tree = Repository.get_content_tree()

    link = Enum.find(tree, fn %{slug: slug} -> slug == "/docs/getting-started/introduction" end)

    assert not is_nil(link)

    # should we really go to the index of the category? Shouldn't we jump straight to the previous post located in the tree?
    assert link.previous.slug == "/docs/getting-started/themes"
    assert link.next.slug == "/docs/setup/how-to-download"

    first = Enum.at(tree, 0)
    assert is_nil(first.previous) and not is_nil(first.next)

    last = List.last(tree)
    assert not is_nil(last.previous) and is_nil(last.next)
  end

  test "post must have its related link and navigation" do
    post = Repository.get_by_slug!("/blog/dailies/3d/blender/default-cube-not-deleted")
    assert post.link.slug == "/blog/dailies/3d/blender/default-cube-not-deleted"
    assert post.link.previous.slug == "/blog/dailies/2d/dachshund-painting"
    assert post.link.next.slug == "/docs/start-here"
  end
end
