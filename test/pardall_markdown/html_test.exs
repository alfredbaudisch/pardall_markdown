defmodule PardallMarkdown.HtmlTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.Content.HtmlUtils

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
               level: 1,
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
