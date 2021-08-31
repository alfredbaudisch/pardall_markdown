defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.Content
  alias LiveMarkdown.Content.Cache
  alias LiveMarkdownWeb.Endpoint
  import LiveMarkdown.Content.Repository.Utils

  def get_all do
    Cache.get_all()
  end

  def get_by_slug!(slug) do
    Cache.get_by_slug(slug) ||
      raise LiveMarkdown.NotFoundError, "post with slug=#{slug} not found"
  end

  def push(path, attrs, content, type \\ :post) do
    model = get_content_model(path)

    model =
      model
      |> Content.changeset(%{
        type: type,
        file_path: path,
        title: attrs.title,
        content: content,
        slug: attrs.slug,
        date: attrs.date,
        is_published: Map.get(attrs, :published, false)
      })
      |> put_timestamps(model)
      |> Ecto.Changeset.apply_changes()

    Cache.save(model)

    Endpoint.broadcast!("content", "post_updated", model)
    Endpoint.broadcast!("post_" <> attrs.slug, "post_updated", model)
  end

  defp get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end

  defp get_content_model(path) do
    %Content{id: get_path_id(path)}
  end
end
