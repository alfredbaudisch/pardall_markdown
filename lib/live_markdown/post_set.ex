defmodule LiveMarkdown.PostSet do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :binary, autogenerate: false}
  @foreign_key_type :slug
  embedded_schema do
    embeds_one :parent_link, LiveMarkdown.Link
    embeds_many :links, LiveMarkdown.Link
    field :sort_by, Ecto.Enum, values: [:title, :date, :slug], default: :date
    field :sort_order, Ecto.Enum, values: [:asc, :desc], default: :desc
  end

  def changeset(model, params) do
    model
    |> cast(params, [:slug, :sort_by, :sort_order])
    |> validate_required([:slug, :sort_by, :sort_order])
    |> cast_embed(:parent_link)
    |> cast_embed(:links)
  end
end
