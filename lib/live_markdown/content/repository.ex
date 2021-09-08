defmodule LiveMarkdown.Content.Repository do
  alias LiveMarkdown.Post
  alias LiveMarkdown.Content.Cache
  alias LiveMarkdownWeb.Endpoint
  import LiveMarkdown.Content.Filters
  require Logger
  alias Ecto.Changeset

  def init do
    Cache.delete_all()
  end

  #
  # CRUD interface
  #

  def get_all_posts(type \\ :all) do
    Cache.get_all_posts(type)
  end

  def get_all_links(type \\ :all) do
    Cache.get_all_links(type)
  end

  def get_taxonomy_tree() do
    Cache.get_taxonomy_tree()
  end

  def get_content_tree() do
    Cache.get_content_tree()
  end

  def get_all_published do
    get_all_posts()
    |> filter_by_is_published()
    |> sort_by_published_date()
  end

  def get_by_slug(slug), do: Cache.get_by_slug(slug)

  def get_by_slug!(slug) do
    get_by_slug(slug) || raise LiveMarkdown.NotFoundError, "Page not found: #{slug}"
  end

  def push_post(path, %{slug: slug, is_index: is_index?} = attrs, content, _type \\ :post) do
    model = get_by_slug(slug) || %Post{}

    model
    |> Post.changeset(%{
      type: get_post_type_from_taxonomies(attrs.categories, is_index?),
      file_path: path,
      title: attrs.title,
      content: content,
      slug: attrs.slug,
      date: attrs.date,
      position: attrs.position,
      summary: Map.get(attrs, :summary, nil),
      is_published: Map.get(attrs, :published, false),
      # for now, when a post is pushed to the repository, only "categories" are known
      taxonomies: attrs.categories,
      metadata: attrs |> remove_default_attributes()
    })
    |> (fn
          %Changeset{valid?: true} = changeset ->
            changeset
            |> Changeset.apply_changes()
            |> save_post()

            Logger.info("Saved post #{slug}")

          changeset ->
            Logger.error("Could not save post #{slug}, errors: #{inspect(changeset.errors)}")
        end).()
  end

  def rebuild_indexes do
    Cache.build_taxonomy_tree()
    Cache.build_content_tree()
  end

  #
  # Data helpers
  #

  # No taxonomy or a post contains only a taxonomy in the root:
  # the post is then considered a page, ex: /about, /contact
  defp get_post_type_from_taxonomies(categories, is_index?)
  defp get_post_type_from_taxonomies(_, true), do: :index
  defp get_post_type_from_taxonomies([], _), do: :page
  defp get_post_type_from_taxonomies([%{slug: "/"}], _), do: :page
  defp get_post_type_from_taxonomies(_, _), do: :post

  defp save_post(%Post{} = model), do: Cache.save_post(model)

  defp save_content_and_broadcast!(%Post{slug: slug} = model) do
    Cache.save_post(model)
    Endpoint.broadcast!("content", "post_updated", model)
    Endpoint.broadcast!("post_" <> slug, "post_updated", model)
  end

  defp remove_default_attributes(attrs) do
    attrs
    |> Map.drop([
      :title,
      :slug,
      :date,
      :summary,
      :published,
      :categories,
      :is_index,
      :position
    ])
  end
end
