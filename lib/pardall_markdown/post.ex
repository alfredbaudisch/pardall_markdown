defmodule PardallMarkdown.Post do
  @moduledoc """
  Fields are self-explanatory. Some special notes:

  - `:is_published`: posts are added to the content trees and archives only when `true`. To retrieve unpublished (draft) posts you have to use `PardallMarkdown.Content.Repository.get_all_posts` or `PardallMarkdown.Content.Repository.get_by_slug`.
  - `:toc`: the generated table of content from the post's Markdown headers.
  - `:type`: a `Post` inside a taxonomy (i.e. inside a subfolder or subfolders) is of type `:post` (example: `"/docs/intro"`), a post inside the root folder is of type `:page` (example: `"/about"`).
  - `:metadata`: additional metadata found in the post's Markdown file definition map.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :string, autogenerate: false}
  @foreign_key_type :string
  embedded_schema do
    field :type, Ecto.Enum, values: [:post, :page, :index], default: :post
    field :title, :string
    field :summary, :string
    field :content, :string
    field :date, :utc_datetime
    field :file_path, :string
    field :is_published, :boolean, default: false
    field :metadata, :map
    field :position, :integer, default: 0
    embeds_many :toc, PardallMarkdown.ContentLink
    embeds_many :taxonomies, PardallMarkdown.Link
    embeds_one :link, PardallMarkdown.Link
  end

  def changeset(model, params) do
    model
    |> cast(params, [
      :type,
      :title,
      :summary,
      :content,
      :slug,
      :date,
      :file_path,
      :is_published,
      :metadata,
      :position
    ])
    |> validate_required([:type, :title, :slug, :date, :file_path])
    |> cast_embed(:taxonomies)
    |> cast_embed(:link)
    |> cast_embed(:toc)
  end
end
