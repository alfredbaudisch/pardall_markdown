defmodule LiveMarkdownWeb.Utils do
  def compose_page_title(title), do: title <> " | " <> site_name()

  def site_name, do: "LiveMarkdown"
end
