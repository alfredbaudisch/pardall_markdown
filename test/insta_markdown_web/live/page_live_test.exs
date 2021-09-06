defmodule LiveMarkdownWeb.PageLiveTest do
  use LiveMarkdownWeb.ConnCase

  import Phoenix.LiveViewTest

  setup do
    Application.ensure_all_started(:live_markdown)
  end

  test "index lists all posts", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "A post in the root is a page"
    assert render(page_live) =~ "A post in the root is a page"
  end

  test "open 3 folders deep post", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/blog/art/3d/nested-post")
    assert disconnected_html =~ "This post has 3 categories in hierarchy (Blog - Art - 3D)."
    assert render(page_live) =~ "This post has 3 categories in hierarchy (Blog - Art - 3D)."
  end
end
