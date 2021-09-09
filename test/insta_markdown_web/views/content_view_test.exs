defmodule LiveMarkdownWeb.ContentViewTest do
  use LiveMarkdownWeb.ConnCase, async: true

  alias LiveMarkdown.Content.Repository

  @tag :link_tree
  test "taxonomy tree HTML link list is generated correctly" do
    tree = Repository.get_content_tree()

    home = List.first(tree)
    assert home.slug == "/"
    assert not is_nil(home.index_post)
    assert home.index_post.content == "<p>\nThis post is supposed to be the Index for Home.</p>\n"
    post = List.first(home.children)
    assert post.slug == "/post"

    blog = Enum.at(tree, 1)
    assert blog.slug == "/blog"

    dailies = List.first(blog.children_links)
    assert dailies.slug == "/blog/dailies"

    dailies_cat = dailies.children_links
    assert Enum.count(dailies.children_links) == 2
    assert List.first(dailies_cat).slug == "/blog/dailies/2d"
    assert List.last(dailies_cat).slug == "/blog/dailies/3d"

    #  assert List.first(tree).title == "Blog"
    generated = link_tree_list(tree)

    expected =
      ~s"""
      <ul>
      <li><a data-phx-link="redirect" data-phx-link-state="push" href="/">Home</a></li>
      <li>
         <a data-phx-link="redirect" data-phx-link-state="push" href="/blog">Blog</a>
         <ul>
            <li>
               <a data-phx-link="redirect" data-phx-link-state="push" href="/blog/dailies">Dailies</a>
               <ul>
                  <li><a data-phx-link="redirect" data-phx-link-state="push" href="/blog/dailies/2d">2D</a></li>
                  <li>
                     <a data-phx-link="redirect" data-phx-link-state="push" href="/blog/dailies/3d">3D</a>
                     <ul>
                        <li><a data-phx-link="redirect" data-phx-link-state="push" href="/blog/dailies/3d/blender">Blender</a></li>
                     </ul>
                  </li>
               </ul>
            </li>
         </ul>
      </li>
      <li>
         <a data-phx-link="redirect" data-phx-link-state="push" href="/docs">Documentation</a>
         <ul>
            <li>
               <a data-phx-link="redirect" data-phx-link-state="push" href="/docs/getting-started">Getting Started</a>
               <ul>
                  <li><a data-phx-link="redirect" data-phx-link-state="push" href="/docs/getting-started/folder">Folder</a></li>
               </ul>
            </li>
            <li><a data-phx-link="redirect" data-phx-link-state="push" href="/docs/setup">Setup</a></li>
            <li><a data-phx-link="redirect" data-phx-link-state="push" href="/docs/advanced-topics">Advanced Topics</a></li>
         </ul>
      </li>
      </ul>
      """
      |> String.replace("\n", "")
      |> String.trim()
      |> String.replace(~r/>\s+</, "><")

    assert generated == expected
  end
end
