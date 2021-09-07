defmodule LiveMarkdownWeb.PageLiveTest do
  use LiveMarkdownWeb.ConnCase

  import Phoenix.LiveViewTest
  alias LiveMarkdown.Content.Repository

  setup do
    Application.ensure_all_started(:live_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(50)
  end

  test "index lists all posts", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "A post in the root is a page"
    assert render(page_live) =~ "A post in the root is a page"
  end

  test "open 3 folders deep post", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/blog/art/3d/nested-post/")
    assert disconnected_html =~ "This post has 3 categories in hierarchy (Blog - Art - 3D)."
    assert render(page_live) =~ "This post has 3 categories in hierarchy (Blog - Art - 3D)."
  end

  test "taxonomy tree is generated correctly", %{conn: _conn} do
    tree = Repository.get_taxonomy_tree()
    generated = taxonomy_tree_list(tree)

    expected =
      ~s"""
      <ul>
      <li><a data-phx-link="redirect" data-phx-link-state="push" href="/">Home</a></li>
      <li>
         <a data-phx-link="redirect" data-phx-link-state="push" href="/blog">Blog</a>
         <ul>
            <li>
               <a data-phx-link="redirect" data-phx-link-state="push" href="/blog/art">Art</a>
               <ul>
                  <li><a data-phx-link="redirect" data-phx-link-state="push" href="/blog/art/3d">3D</a></li>
               </ul>
            </li>
         </ul>
      </li>
      </ul>
      """
      |> String.replace("\n", "")
      |> String.trim()
      |> String.replace(~r/>\s+</, "><")

    assert generated == expected

    fragment = Floki.parse_fragment!(generated)

    assert Enum.count(Floki.find(fragment, "li")) == Enum.count(tree)

    # /blog/art/3d
    assert Enum.count(Floki.find(fragment, "ul")) == 3

    # /blog/art/3d - link 3 levels deep
    assert fragment
           |> Floki.find("ul > li > ul > li > ul > li > a")
           |> Floki.text() == "3D"
  end
end
