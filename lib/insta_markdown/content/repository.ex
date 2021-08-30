defmodule InstaMarkdown.Content.Repository do
  alias InstaMarkdown.Content.{Cache, Utils}
  alias InstaMarkdown.Endpoint

  def push(path, content, title) do
    Cache.save(path, %{
      content: content,
      title: title
    })
  end

  defp get_slug_from_path(path) do
    path
    |> String.replace(Utils.root_folder(), "")
    |> Slug.slugify()
  end
end
