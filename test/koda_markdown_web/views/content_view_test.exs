defmodule KodaMarkdownWeb.ContentViewTest do
  use KodaMarkdownWeb.ConnCase, async: true

  alias KodaMarkdown.Content.Repository

  test "taxonomy tree is generated correctly" do
    tree = Repository.get_taxonomy_tree()
    assert List.first(tree).title == "Blog"
    generated = taxonomy_tree_list(tree)

    expected = ~s"""
    <ul>
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
                      <li><a data-phx-link="redirect" data-phx-link-state="push" href="/blog/dailies/3d/blender">Blender</a>
                   </ul>
                </li>
             </ul>
          </li>
       </ul>
    </li>
    <li>
       <a data-phx-link="redirect" data-phx-link-state="push" href="/docs">Docs</a>
       <ul>
          <li><a data-phx-link="redirect" data-phx-link-state="push" href="/docs/advanced-topics">Advanced Topics</a></li>
          <li><a data-phx-link="redirect" data-phx-link-state="push" href="/docs/getting-started">Getting Started</a></li>
          <li><a data-phx-link="redirect" data-phx-link-state="push" href="/docs/setup">Setup</a></li>
       </ul>
    </li>
    </ul>
    """

    assert generated == expected

    fragment = Floki.parse_fragment!(generated)

    assert Enum.count(Floki.find(fragment, "li")) == Enum.count(tree)

    # /blog/dailies/3d
    assert Enum.count(Floki.find(fragment, "ul")) == 5
  end
end
