defmodule KodaMarkdown.ContentLink do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary, autogenerate: false}
  @foreign_key_type :id
  embedded_schema do
    field :title, :string
    field :level, :integer, default: 1
    field :parent_slug, :string
  end

  def changeset(model, params) do
    model
    |> cast(params, [
      :id,
      :title,
      :level,
      :parent_slug
    ])
    |> validate_required([
      :id,
      :title,
      :level,
      :parent_slug
    ])
  end
end
