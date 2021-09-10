defmodule LiveMarkdown.RepositoryTest do
  use ExUnit.Case, async: true
  alias LiveMarkdown.Content.{Tree, Repository}
  alias LiveMarkdown.Link

  setup do
    Application.ensure_all_started(:live_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(100)
  end

  test "getting a taxonomy archive via content tree should return all posts from the hierarchy top down" do
    twod = Repository.get_content_tree("/blog/dailies/2d")
    assert List.first(twod.children).slug == "/blog/dailies/2d/dachshund-painting"
    assert List.last(twod.children).slug == "/blog/dailies/2d/ant-painting"

    blog = Repository.get_content_tree("/blog")

    dailies = Repository.get_content_tree("/blog/dailies")
    assert List.first(dailies.children_links).slug == "/blog/dailies/3d"
    assert List.last(dailies.children_links).slug == "/blog/dailies/2d"

    posts = dailies |> Tree.get_all_posts_from_tree()

    assert Enum.count(posts) == 3
    assert List.first(posts).slug == "/blog/dailies/3d/blender/default-cube-not-deleted"
    assert Enum.at(posts, 1).slug == "/blog/dailies/first-day"
    assert List.last(posts).slug == "/blog/dailies/2d/dachshund-painting"
  end

  test "content tree should be split per slug into cache and everything should be order accordingly" do
    docs = Repository.get_content_tree("/docs")
    assert List.first(docs.children_links).slug == "/docs/getting-started"
    assert Enum.at(docs.children_links, 1).slug == "/docs/setup"
    assert List.last(docs.children_links).slug == "/docs/advanced-topics"

    #
    # Getting started
    #
    tree = Repository.get_content_tree("/docs/getting-started")
    assert tree.slug == "/docs/getting-started"
    assert Enum.count(tree.children_links) == 1
    assert Enum.count(tree.children) == 3

    intro = Enum.at(tree.children, 0)
    assert intro.slug == "/docs/getting-started/introduction"

    installation = Enum.at(tree.children, 1)
    assert installation.slug == "/docs/getting-started/installation-and-setup"

    themes = Enum.at(tree.children, 2)
    assert themes.slug == "/docs/getting-started/customization"

    #
    # Advanced topics
    #
    tree = Repository.get_content_tree("/docs/advanced-topics")
    intro = Enum.at(tree.children, 0)
    assert intro.title == "Advanced Topic #2 - Reversed on purpose"
    intro = Enum.at(tree.children, 1)
    assert intro.title == "Advanced Topic #1"

    #
    # Advanced topics
    #
    tree = Repository.get_content_tree("/docs/setup")
    intro = Enum.at(tree.children, 0)
    assert intro.title == "How to Download for any Platform"
    intro = Enum.at(tree.children, 1)
    assert intro.title == "Deployment"
  end

  test "taxonomies should be sorted by their closest sorting method" do
    tree =
      Repository.get_taxonomy_tree()
      |> Enum.filter(fn %{type: type} -> type == :taxonomy end)

    assert Enum.count(tree) == 2
  end

  @tag :here
  test "post must have its related link" do
    post = Repository.get_by_slug!("/blog/dailies/3d/blender/default-cube-not-deleted")
    assert post.link.slug == "/blog/dailies/3d/blender/default-cube-not-deleted"
    assert post.link.next.slug == "/blog/dailies/first-day"
    assert post.link.previous.slug == nil
  end

  def print_tree(links, all \\ "<ul>", previous_level \\ -1)

  def print_tree([%Link{slug: slug, children_links: children} | tail], all, -1) do
    all = all <> "<li>" <> slug
    all_children = print_tree(children)
    print_tree(tail, all <> all_children, 1)
  end

  def print_tree([%Link{slug: slug, children_links: children} | tail], all, previous_level) do
    all = all <> "</li><li>" <> slug
    all_children = print_tree(children)
    print_tree(tail, all <> all_children, previous_level)
  end

  def print_tree([], "<ul>", _), do: ""
  def print_tree([], all, _), do: all <> "</li></ul>"

  def link(slug), do: slug
end
