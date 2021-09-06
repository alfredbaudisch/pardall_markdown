defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.{Post, Taxonomy}
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

  def get_all_posts do
    Cache.get_all_posts()
  end

  def get_all_published do
    get_all_posts()
    |> filter_by_is_published()
    |> sort_by_published_date()
  end

  def get_by_slug(slug), do: Cache.get_by_slug(slug)

  def get_by_slug!(slug) do
    get_by_slug(slug) ||
      raise LiveMarkdown.NotFoundError, "Post not found: #{slug}"
  end

  def push_post(path, %{slug: slug} = attrs, content, type \\ :post) do
    model = get_by_slug(slug) || %Post{}

    model
    |> Post.changeset(%{
      type: type,
      file_path: path,
      title: attrs.title,
      content: content,
      slug: attrs.slug,
      date: attrs.date,
      is_published: Map.get(attrs, :published, false),
      # for now, when a post is pushed to the repository, only "categories" are known
      taxonomies: attrs.categories
    })
    |> put_timestamps(model)
    |> Ecto.Changeset.apply_changes()
    |> save_content_and_broadcast!()
  end

  def delete_path(path) do
    case Cache.delete_path(path) do
      [_p | _] = posts ->
        Endpoint.broadcast!("content", "post_events", posts)

        for {slug, :deleted} <- posts do
          Endpoint.broadcast!("post_" <> slug, "post_deleted", true)
        end

      _ ->
        []
    end
  end

  #
  # Data helpers
  #

  defp save_content_and_broadcast!(
         %Post{id: nil, file_path: path, taxonomies: taxonomies, slug: slug} = model
       ) do
    model = %{model | id: get_path_id(path)}
    save_taxonomies(taxonomies, slug)
    Cache.save_post(model)
    Endpoint.broadcast!("content", "post_created", model)
  end

  defp save_content_and_broadcast!(%Post{slug: slug, taxonomies: taxonomies} = model) do
    save_taxonomies(taxonomies, slug)
    Cache.save_post(model)
    Endpoint.broadcast!("content", "post_updated", model)
    Endpoint.broadcast!("post_" <> slug, "post_updated", model)
  end

  defp save_taxonomies([%Taxonomy{} = _ | _] = taxonomies, post_slug) do
    taxonomies
    |> Enum.map(&Cache.save_taxonomy_with_post(&1, post_slug))
  end

  defp get_path_id(path) do
    :crypto.hash(:sha, path) |> Base.encode16() |> String.downcase()
  end
end
