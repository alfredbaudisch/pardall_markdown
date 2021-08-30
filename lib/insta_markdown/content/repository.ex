defmodule InstaMarkdown.Content.Repository do
  alias InstaMarkdown.Content.Cache

  def push(path, content, opts \\ []) do
  end

  defp get_slug_from_path(path) do
    path
    |> String.replace(Utils.root_folder(), "")
    |> Slug.slugify()
  end
end
