defmodule LiveMarkdown.RepositoryTest do
  use ExUnit.Case, async: true
  alias LiveMarkdown.Content.{Cache, Repository}

  setup do
    Application.ensure_all_started(:live_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(100)
  end

  @tag :sorting
  test "taxonomies should be sorted by their closest sorting method" do
    tree =
      Cache.get_taxonomy_tree()
      |> Enum.filter(fn %{type: type} -> type == :taxonomy end)

    tree
    |> Enum.map(fn %{slug: slug, parents: parents} -> %{slug: slug, parents: parents} end)
    |> IO.inspect()

    slugs =
      tree
      |> Enum.map(& &1.slug)
      |> IO.inspect()

    assert Enum.at(slugs, 0) == "/blog"
    assert Enum.at(slugs, 1) == "/blog/dailies"
    assert Enum.at(slugs, 2) == "/blog/dailies/2d"
    assert Enum.at(slugs, 3) == "/blog/dailies/3d"
    assert Enum.at(slugs, 4) == "/blog/dailies/3d/blender"
    assert Enum.at(slugs, 5) == "/docs"
    assert Enum.at(slugs, 6) == "/docs/getting-started"
    assert Enum.at(slugs, 7) == "/docs/setup"
    assert Enum.at(slugs, 8) == "/docs/advanced-topics"
  end

  # still not accounting for per-folder indexing
  test "content tree previous and next links" do
    tree = Repository.get_content_tree()

    link = Enum.find(tree, fn %{slug: slug} -> slug == "/docs/getting-started/introduction" end)

    assert not is_nil(link)

    # should we really go to the index of the category? Shouldn't we jump straight to the previous post located in the tree?
    assert link.previous.slug == "/docs/getting-started/themes"
    assert link.next.slug == "/docs/setup"

    first = Enum.at(tree, 0)
    assert is_nil(first.previous) and not is_nil(first.next)

    last = List.last(tree)
    assert not is_nil(last.previous) and is_nil(last.next)
  end

  test "post must have its related link" do
    post = Repository.get_by_slug!("/blog/dailies/3d/blender/default-cube-not-deleted")
    assert post.link.slug == "/blog/dailies/3d/blender/default-cube-not-deleted"
    assert post.link.previous.slug == "/blog/dailies/3d/blender"
    assert post.link.next.slug == "/docs"
  end
end
