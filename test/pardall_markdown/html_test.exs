defmodule PardallMarkdown.HtmlTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.Content.HtmlUtils

  @moduletag :html_utils
  doctest(PardallMarkdown.Content.HtmlUtils)

  @tag :post_summary
  test "generate post summary" do
    html = ~S"""
    <h1>Post Title</h1>

    <main>
    <article>
      <div>
        <p>So, <a href="link">a description</a> will be generated from it. Even a <span>nested span</span>.</p>
        <p>Another paragraph?</p>
        <p>Another paragraph 2?</p>
        <p>Another paragraph 3?</p>
        <p>As you can see, this a very long paragraph. As you can see, this a very long paragraph. As you can see, this a very long paragraph. As you can see, this a very long paragraph. As you can see, this a very long paragraph. As you can see, this a very long paragraph. As you can see, this a very long paragraph. As you can see, this a very long paragraph. </p>
      </div>
    </article>
    </main>

    <p>As you can see, this a paragraph outside.</p>

    This is <a name="anchor">an anchor</a>.
    """

    assert HtmlUtils.generate_summary_from_html(html) == "So, a description will be generated from it. Even a nested span. Another paragraph? Another paragraph 2? Another paragraph 3? As you can see, this a very long..."

    html = ~S"""
    <h1>Post Title</h1>

    <main><article><div><p>So, <a href="link">a description</a> will be generated from it. Even a <span>nested span</span>.</p></div></article></main>

    <p>As you can see, this a long paragraph outside.</p>This is <a name="anchor">an anchor</a>.
    """

    assert HtmlUtils.generate_summary_from_html(html) == "So, a description will be generated from it. Even a nested span. As you can see, this a long paragraph outside."

    html = "<p>Do not delete Blender's Default Cube!</p>"

    assert HtmlUtils.generate_summary_from_html(html) == "Do not delete Blender's Default Cube!"
  end

  test "make internal <a/> links as live links" do
    html = ~S"""
    This <a href="docs">is</a> <a href="/blog" class="foo" id="boo">a link</a> to <a href="../../wiki">an</a> internal <a href="v1.0_release">post</a>.

    This <a href="mailto:phoenix@liveview.com">is</a> an <a href="https://elixir-lang.org">external link</a>.

    This is <a name="anchor">an anchor</a>.
    """

    {:ok, html} = HtmlUtils.convert_internal_links_to_live_links(html)

    target_html =
      ~S"""
      This <a data-phx-link="redirect" data-phx-link-state="push" href="docs">is</a><a data-phx-link="redirect" data-phx-link-state="push" href="/blog" class="foo" id="boo">a link</a> to <a data-phx-link="redirect" data-phx-link-state="push" href="../../wiki">an</a> internal <a data-phx-link="redirect" data-phx-link-state="push" href="v1.0-release">post</a>.

      This <a href="mailto:phoenix@liveview.com">is</a> an <a href="https://elixir-lang.org">external link</a>.

      This is <a name="anchor">an anchor</a>.
      """
      |> HtmlUtils.strip_in_between_space()

    assert html |> HtmlUtils.strip_in_between_space() == target_html
  end

  @tag :toc_header_nesting
  test "correctly generate TOC nesting from header nesting, example 1" do
    html = ~S"""
    <h2>Header 2, Level 1</h2>
    <h3>Header 3, Level 2</h3>
    <h4>Header 4, Level 3</h4>

    <h2>Header 2, Level 1</h2>

    <h1>Header 1, Level 1</h1>
    <h4>Header 4, Level 2</h4>
    <h3>Header 3, Level 2</h3>
    Some content...
    """

    {:ok, _html, toc} =
      html |> HtmlUtils.generate_anchors_and_toc(%{slug: "/headers", title: "Title"})

    assert toc == [
      %{
        id: "#header-2-level-1",
        header: 2,
        level: 1,
        parent_slug: "/headers",
        title: "Header 2, Level 1"
      },
      %{
        id: "#header-3-level-2",
        header: 3,
        level: 2,
        parent_slug: "/headers",
        title: "Header 3, Level 2"
      },
      %{
        id: "#header-4-level-3",
        header: 4,
        level: 3,
        parent_slug: "/headers",
        title: "Header 4, Level 3"
      },
      %{
        id: "#header-2-level-1-1",
        header: 2,
        level: 1,
        parent_slug: "/headers",
        title: "Header 2, Level 1"
      },
      %{
        id: "#header-1-level-1",
        header: 1,
        level: 1,
        parent_slug: "/headers",
        title: "Header 1, Level 1"
      },
      %{
        id: "#header-4-level-2",
        header: 4,
        level: 2,
        parent_slug: "/headers",
        title: "Header 4, Level 2"
      },
      %{
        id: "#header-3-level-2-1",
        header: 3,
        level: 2,
        parent_slug: "/headers",
        title: "Header 3, Level 2"
      }
    ]
  end

  @tag :toc_header_nesting
  test "correctly generate TOC nesting from header nesting, example 2" do
    html = ~S"""
    <h2>H2  Level 1</h2>
    <h3>H3 Level 2</h3>
    <h4>H4, Level 3</h4>

    <h2>H2 Level 1</h2>

    <h1>H1 Level 1</h1>
    <h4>H4 Level 2</h4>
    <h3>H3 Level 2</h3>
    <h2>H2 Level 2</h2>
    <h5>H5 Level 3</h5>
    <h4>H4 Level 3</h4>
    """

    {:ok, _html, toc} =
      html |> HtmlUtils.generate_anchors_and_toc(%{slug: "/headers", title: "Title"})

    assert toc == [
      %{
        header: 2,
        id: "#h2-level-1",
        level: 1,
        parent_slug: "/headers",
        title: "H2  Level 1"
      },
      %{
        header: 3,
        id: "#h3-level-2",
        level: 2,
        parent_slug: "/headers",
        title: "H3 Level 2"
      },
      %{
        header: 4,
        id: "#h4-level-3",
        level: 3,
        parent_slug: "/headers",
        title: "H4, Level 3"
      },
      %{
        header: 2,
        id: "#h2-level-1-1",
        level: 1,
        parent_slug: "/headers",
        title: "H2 Level 1"
      },
      %{
        header: 1,
        id: "#h1-level-1",
        level: 1,
        parent_slug: "/headers",
        title: "H1 Level 1"
      },
      %{
        header: 4,
        id: "#h4-level-2",
        level: 2,
        parent_slug: "/headers",
        title: "H4 Level 2"
      },
      %{
        header: 3,
        id: "#h3-level-2-1",
        level: 2,
        parent_slug: "/headers",
        title: "H3 Level 2"
      },
      %{
        header: 2,
        id: "#h2-level-2",
        level: 1,
        parent_slug: "/headers",
        title: "H2 Level 2"
      },
      %{
        header: 5,
        id: "#h5-level-3",
        level: 3,
        parent_slug: "/headers",
        title: "H5 Level 3"
      },
      %{
        header: 4,
        id: "#h4-level-3-1",
        level: 3,
        parent_slug: "/headers",
        title: "H4 Level 3"
      }
    ]
  end

  @tag :toc_header_nesting
  test "header nesting correctly generate toc when header level changes" do
    html = ~S"""
    <h2>First Header</h2>
    Some content...

    <h2>Second Header</h2>
    Some content...
    """

    {:ok, _html, toc} =
      html |> HtmlUtils.generate_anchors_and_toc(%{slug: "/headers", title: "Title"})

    assert toc == [
      %{
        id: "#first-header",
        level: 1,
        header: 2,
        parent_slug: "/headers",
        title: "First Header"
      },
      %{
        id: "#second-header",
        header: 2,
        level: 1,
        parent_slug: "/headers",
        title: "Second Header"
      }
    ]

    html = ~S"""
    <h2>Header 2, Level 1</h2>
    <h3>Header 3, Level 2</h3>
    <h4>Header 4, Level 3</h4>

    <h2>Header 2, Level 1</h2>

    <h1>Header 1, Level 1</h1>
    <h4>Header 4, Level 2</h4>
    <h3>Header 3, Level 2</h3>
    Some content...
    """

    {:ok, _html, toc} =
      html |> HtmlUtils.generate_anchors_and_toc(%{slug: "/headers", title: "Title"})

    assert toc == [
      %{
        id: "#header-2-level-1",
        header: 2,
        level: 1,
        parent_slug: "/headers",
        title: "Header 2, Level 1"
      },
      %{
        id: "#header-3-level-2",
        header: 3,
        level: 2,
        parent_slug: "/headers",
        title: "Header 3, Level 2"
      },
      %{
        id: "#header-4-level-3",
        header: 4,
        level: 3,
        parent_slug: "/headers",
        title: "Header 4, Level 3"
      },
      %{
        id: "#header-2-level-1-1",
        header: 2,
        level: 1,
        parent_slug: "/headers",
        title: "Header 2, Level 1"
      },
      %{
        id: "#header-1-level-1",
        header: 1,
        level: 1,
        parent_slug: "/headers",
        title: "Header 1, Level 1"
      },
      %{
        id: "#header-4-level-2",
        header: 4,
        level: 2,
        parent_slug: "/headers",
        title: "Header 4, Level 2"
      },
      %{
        id: "#header-3-level-2-1",
        header: 3,
        level: 2,
        parent_slug: "/headers",
        title: "Header 3, Level 2"
      }
    ]
  end

  test "add ids and anchors to heading, ids and anchors should be unique, even if the title is repeated" do
    html = ~S"""
    <h3>This item should be level 1 in the TOC</h3>
    <h1 name="foo">First Section <strong>Name</strong></h1>

    Content content

    <h2>Inner- "Title"</h2>

    Content Content

    <h1>Second Section</h1>

    <h2>Inner- "Title"</h2>
    """

    {:ok, html, toc} =
      html |> HtmlUtils.generate_anchors_and_toc(%{slug: "/foo", title: "Sample Page"})

    target_html =
      ~S"""
      <h3 id="this-item-should-be-level-1-in-the-toc"><a href="#this-item-should-be-level-1-in-the-toc" class="anchor-link __pardall-anchor-link" data-title="This item should be level 1 in the TOC"></a>This item should be level 1 in the TOC</h3>

      <h1 id="first-section" name="foo"><a href="#first-section" class="anchor-link __pardall-anchor-link" data-title="First Section"></a>First Section <strong>Name</strong></h1>

      Content content

      <h2 id="inner-title"><a href="#inner-title" class="anchor-link __pardall-anchor-link" data-title="Inner- &quot;Title&quot;"></a>Inner- &quot;Title&quot;</h2>

      Content Content

      <h1 id="second-section"><a href="#second-section" class="anchor-link __pardall-anchor-link" data-title="Second Section"></a>Second Section</h1><h2 id="inner-title-1"><a href="#inner-title-1" class="anchor-link __pardall-anchor-link" data-title="Inner- &quot;Title&quot;"></a>Inner- &quot;Title&quot;</h2>
      """
      |> HtmlUtils.strip_in_between_space()

    assert html |> HtmlUtils.strip_in_between_space() == target_html

    assert toc == [
             %{
               id: "#this-item-should-be-level-1-in-the-toc",
               level: 3,
               parent_slug: "/foo",
               title: "This item should be level 1 in the TOC"
             },
             %{id: "#first-section", level: 1, parent_slug: "/foo", title: "First Section"},
             %{id: "#inner-title", level: 2, parent_slug: "/foo", title: "Inner- \"Title\""},
             %{id: "#second-section", level: 1, parent_slug: "/foo", title: "Second Section"},
             %{id: "#inner-title-1", level: 2, parent_slug: "/foo", title: "Inner- \"Title\""}
           ]

    assert Enum.count(toc) == 5

    # Make sure ids are unique in the toc, since in the HTML we have two titles that are the same
    Enum.reduce(toc, %{}, fn %{id: id}, acc ->
      assert is_nil(Map.get(acc, :id))
      Map.put(acc, id, 1)
    end)
  end
end
