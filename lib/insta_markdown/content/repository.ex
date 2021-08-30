defmodule InstaMarkdown.Content.Repository do
  alias InstaMarkdown.Content
  alias InstaMarkdown.Content.{Cache, Utils}
  alias InstaMarkdownWeb.Endpoint
  alias Ecto.Changeset

  def push(path, content, title, type \\ :html) do
    slug = get_slug_from_path(path, type)
    model = get_content(path)

    changeset =
      Content.changeset(model, %{
        type: type,
        path: path,
        title: title,
        content: content,
        slug: slug,
        url: slug
      })
      |> put_timestamps(model)

    Cache.save(path, changeset |> Ecto.Changeset.apply_changes())
  end

  def get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end

  defp get_content(path) do
    %Content{id: get_path_id(path)}
  end

  defp get_slug_from_path(path, type) do
    cond do
      type in [:text, :html] ->
        path
        |> String.replace(Path.extname(path), "")

      true ->
        path
    end
    |> String.replace(Utils.root_folder(), "")
    |> Slug.slugify(ignore: "/")
  end

  defp put_timestamps(changeset, %Content{inserted_at: nil}) do
    now = NaiveDateTime.utc_now()

    changeset
    |> Changeset.put_change(:inserted_at, now)
    |> Changeset.put_change(:updated_at, now)
  end

  defp put_timestamps(changeset, _model) do
    changeset
    |> Changeset.put_change(:updated_at, NaiveDateTime.utc_now())
  end
end
