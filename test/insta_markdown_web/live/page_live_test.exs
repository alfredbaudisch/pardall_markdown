defmodule LiveMarkdownWeb.PageLiveTest do
  use LiveMarkdownWeb.ConnCase

  import Phoenix.LiveViewTest

  test "index lists all posts", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "A post in the root is a page"
    assert render(page_live) =~ "A post in the root is a page"
  end

  test "open 3 folders deep post", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/blog/dailies/2d/dachshund-painting/")
    assert disconnected_html =~ "This post has 3 categories in hierarchy (Blog - Dailies - 2D)."
    assert render(page_live) =~ "This post has 3 categories in hierarchy (Blog - Dailies - 2D)."

    assert render(page_live)
           |> Floki.parse_document!()
           |> Floki.find("img")
           |> Enum.count() == 1
  end
end
