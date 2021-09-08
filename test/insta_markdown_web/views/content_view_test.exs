defmodule LiveMarkdownWeb.ContentViewTest do
  use LiveMarkdownWeb.ConnCase, async: true

  alias LiveMarkdown.Content.Repository

  test "taxonomy tree is generated correctly" do
    tree = Repository.get_taxonomy_tree()
    generated = taxonomy_tree_list(tree)

    expected =
      ~s"""
      <ul>
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
