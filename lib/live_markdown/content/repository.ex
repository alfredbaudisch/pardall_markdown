defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.Content
  alias LiveMarkdown.Content.Cache
  alias LiveMarkdownWeb.Endpoint
  import LiveMarkdown.Content.Repository.Utils
  import LiveMarkdown.Content.Repository.Filters
  require Logger

  def init do
    Cache.delete_all()
  end

  #
  # CRUD interface
  #

  def get_all do
    Cache.get_all()
  end

  def get_all_published do
    get_all()
    |> filter_by_is_published()
    |> sort_by_published_date()
  end

  def get_by_slug(slug), do: Cache.get_by_slug(slug)

  def get_by_slug!(slug) do
    get_by_slug(slug) ||
      raise LiveMarkdown.NotFoundError, "post with slug=#{slug} not found"
  end

  def push(path, %{slug: slug} = attrs, content, type \\ :post) do
    model = get_by_slug(slug) || %Content{}

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
    |> save_content_and_broadcast!()
  end

  def delete_path(path) do
    posts = Cache.delete_path(path)
    Endpoint.broadcast!("content", "post_events", posts)

    for {slug, :deleted} <- posts do
      Endpoint.broadcast!("post_" <> slug, "post_deleted", true)
    end
  end

  #
  # Data helpers
  #

  defp save_content_and_broadcast!(%Content{id: nil, file_path: path} = model) do
    model = %{model | id: get_path_id(path)}
    Cache.save(model)
    Endpoint.broadcast!("content", "post_created", model)
  end

  defp save_content_and_broadcast!(%Content{slug: slug} = model) do
    Cache.save(model)
    Endpoint.broadcast!("content", "post_updated", model)
    Endpoint.broadcast!("post_" <> slug, "post_updated", model)
  end

  defp get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end
end
