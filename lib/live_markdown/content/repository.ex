defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.Content
  alias LiveMarkdown.Content.{Cache, Utils}
  alias LiveMarkdownWeb.Endpoint
  import LiveMarkdown.Content.Repository.Utils

  def get_all do
    Cache.get_all()
  end

  def push(path, attrs, content, type \\ :post) do
    model = get_content(path)

    model =
      model
      |> Content.changeset(%{
        type: type,
        path: path,
        title: attrs.title,
        content: content,
        slug: attrs.slug,
        url: attrs.slug,
        date: attrs.date
      })
      |> put_timestamps(model)
      |> Ecto.Changeset.apply_changes()

    Cache.save(path, model)

    Endpoint.broadcast!("content", "post_updated", model)
  end

  def get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end

  defp get_content(path) do
    %Content{id: get_path_id(path)}
  end
end
