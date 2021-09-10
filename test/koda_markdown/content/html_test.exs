defmodule KodaMarkdown.HtmlTest do
  use ExUnit.Case, async: true
  alias KodaMarkdown.Content.HtmlUtils

  test "add ids and anchors to heading, ids and anchors should be unique, even if the title is repeated" do
    html = ~S"""
    <h1 name="foo">First Section <strong>Name</strong></h1>

    Content content

    <h2>Inner- "Title"</h2>

    Content Content

    <h1>Second Section</h1>

    <h2>Inner- "Title"</h2>
    """

    html = html |> HtmlUtils.add_ids_and_anchors_to_headings()

    target_html =
      ~S"""
      <h1 id="first-section" name="foo"><a href="#first-section" class="anchor-link" data-title="First Section"></a>First Section <strong>Name</strong></h1>

      Content content

      <h2 id="inner-title"><a href="#inner-title" class="anchor-link" data-title="Inner- &quot;Title&quot;"></a>Inner- &quot;Title&quot;</h2>

      Content Content

      <h1 id="second-section"><a href="#second-section" class="anchor-link" data-title="Second Section"></a>Second Section</h1><h2 id="inner-title-1"><a href="#inner-title-1" class="anchor-link" data-title="Inner- &quot;Title&quot;"></a>Inner- &quot;Title&quot;</h2>
      """
      |> HtmlUtils.strip_in_between_space()

    assert html |> HtmlUtils.strip_in_between_space() == target_html
  end
end
