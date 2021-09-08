defmodule LiveMarkdown.Post do
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
    field :priority, :integer, default: 0
    embeds_many :taxonomies, LiveMarkdown.Link
    embeds_one :link, LiveMarkdown.Link
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
      :priority
    ])
    |> validate_required([:type, :title, :slug, :date, :file_path])
    |> cast_embed(:taxonomies)
    |> cast_embed(:link)
  end
end
