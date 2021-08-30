defmodule LiveMarkdown.Content.Utils do
  def root_folder, do: Application.get_env(:live_markdown, LiveMarkdown.Content)[:root_folder]
end
