defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.Content
  alias LiveMarkdown.Content.{Cache, Utils}
  alias LiveMarkdownWeb.Endpoint
  import LiveMarkdown.Content.Repository.Utils

  def push(path, content, title, type \\ :html) do
    slug = Utils.get_slug_from_path(path, type)
    model = get_content(path)

    changeset =
      model
      |> Content.changeset(%{
        type: type,
        path: path,
        title: title,
        content: content,
        slug: slug,
        url: slug
      })
      |> put_timestamps(model)
      |> Ecto.Changeset.apply_changes()

    Cache.save(path, changeset)

    Endpoint.broadcast!("content", "content_updated", changeset)
  end

  def get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end

  defp get_content(path) do
    %Content{id: get_path_id(path)}
  end
end
