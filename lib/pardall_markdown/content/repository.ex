defmodule PardallMarkdown.Content.Repository do
  @moduledoc """
  Provides the necessary API to retrieve and save parsed content.

  Preferrably, use only the `get_*` functions. The `build_*` and
  `save_*` functions are used by other PardallMarkdown modules.

  ## Understanding taxonomy Post archives (`Link.children`):
  - Posts are saved individually (to be retrieved with `PardallMarkdown.Content.Repository.get_by_slug("/a/post/slug")`) and under their taxonomies and taxonomies' hierarchy. A taxonomy archive (all posts of a taxonomy) and its hierarchy are contained in `PardallMarkdown.Link.children` when the taxonomy is retrieved by:
    - `PardallMarkdown.Content.Repository.get_by_slug("/taxonomy/inner-taxonomy")`
    - `PardallMarkdown.Content.Repository.get_content_tree("/taxonomy/inner-taxonomy")`
    - `PardallMarkdown.Content.Repository.get_content_tree("/")` - root, which contains all taxonomies, their posts and hierarchy.
  - **When retrieving a taxonomy by slug** with `PardallMarkdown.Content.Repository.get_by_slug("/taxonomy/name")` the taxonomy `:children` contains all posts from all of its innermost taxonomies `:children`.
    - For example, the post: "/blog/news/city/foo" appears inside the `:children` of 3 taxonomies: `"/blog"`, `"/blog/news"` and `"/blog/news/city"`.
  - On the other hand, **taxonomies in the content tree** retrieved with `PardallMarkdown.Content.Repository.get_content_tree/1` contains only their immediate children posts.
    - For example, the post: "/blog/news/city/foo" appears only inside the `:children` its definying taxonomy: `"/blog/news/city"`.
  """

  alias PardallMarkdown.Post
  alias PardallMarkdown.Content.Cache
  import PardallMarkdown.Content.Filters
  require Logger
  alias Ecto.Changeset

  def init do
    Cache.delete_all()
  end

  #
  # CRUD interface
  #

  @doc """
  Gets all posts, unordered.

  `type`:
  - `:all`: all posts
  - `:post`: posts inside taxonomies
  - `:page`: posts at the root level "/"
  """
  def get_all_posts(type \\ :all) do
    Cache.get_all_posts(type)
  end

  @doc """
  Gets all links, ordered by slug
  `type`:
  - `:all`
  - `:taxonomy`: only taxonomy links
  - `:post`: only post links
  """
  def get_all_links(type \\ :all) do
    Cache.get_all_links(type)
  end

  @doc """
  Gets a map with all links, where the map keys are the links' slugs.
  `type`:
  - `:all`
  - `:taxonomy`: only taxonomy links
  - `:post`: only post links
  """
  def get_all_links_indexed_by_slug(type \\ :all) do
    Cache.get_all_links_indexed_by_slug(type)
  end

  @doc """
  Gets the content taxonomy tree, ordered
  and nested by `Link.level`
  """
  def get_taxonomy_tree() do
    Cache.get_taxonomy_tree()
  end

  @doc """
  Gets content trees. The content tree contains
  nested taxonomies and their nested posts.

  Posts are nested inside their innermost taxonomy.
  Posts are sorted by their outmost taxonomy sorting rules.

  `slug`:
  - `"/"`: content tree for all content
  - `"/taxonomy"`: content tree for the given taxonomy slug.
  Any level can be provided and the tree will be returned accordingly, example:
  "/any/nesting/level": taxonomies and posts that start at "/any/nesting/level",
  including "/any/nesting/level" itself.
  """
  def get_content_tree(slug \\ "/") do
    Cache.get_content_tree(slug)
  end

  def get_all_published do
    get_all_posts()
    |> filter_by_is_published()
  end

  @doc """
  Gets a single post or taxonomy by slug.

  Returns `Post` (single post) or `Link` (taxonomy and its :children)
  """
  def get_by_slug(slug), do: Cache.get_by_slug(slug)

  @doc """
  Same as `get_by_slug/1` but raises `PardallMarkdown.NotFoundError`
  if slug not found.
  """
  def get_by_slug!(slug) do
    get_by_slug(slug) || raise PardallMarkdown.NotFoundError, "Page not found: #{slug}"
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
      summary: Map.get(attrs, :summary, nil),
      is_published: Map.get(attrs, :published, false),
      # for now, when a post is pushed to the repository, only "categories" are known
      taxonomies: attrs.categories,
      metadata: attrs |> remove_default_attributes(),
      position: Map.get(attrs, :position, 0),
      toc: attrs.toc
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

  @doc """
  Rebuild indexes and then notify with a custom callback that the content has been reloaded.

  The notification can be used, for example, to perform a Phoenix.Endpoint
  broadcast, then a website which implements `Phoenix.Channel` or `Phoenix.LiveVew`
  can react accordingly.

  The notification callback must be put inside the application configuration key `:notify_content_reloaded`.

  Example:
  ```
  config :pardall_markdown, PardallMarkdown.Content,
    notify_content_reloaded: &Website.notify/0
  ```
  """
  def rebuild_indexes do
    Cache.build_taxonomy_tree()
    Cache.build_content_tree()

    notify_content_reloaded =
      Application.get_env(:pardall_markdown, PardallMarkdown.Content)[:notify_content_reloaded]

    cond do
      is_function(notify_content_reloaded) -> notify_content_reloaded.()
      true -> {:ok, :reloaded}
    end
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

  defp remove_default_attributes(attrs) do
    attrs
    |> Map.drop([:title, :slug, :date, :summary, :published, :categories, :is_index, :toc])
  end
end
