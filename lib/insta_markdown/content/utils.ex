defmodule InstaMarkdown.Content.Utils do
  def root_folder, do: Application.get_env(:insta_markdown, InstaMarkdown.Content)[:root_folder]
end
