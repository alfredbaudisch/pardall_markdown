defmodule LiveMarkdown.Taxonomy do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :binary, autogenerate: false}
  @foreign_key_type :slug
  embedded_schema do
    field :name, :string

    # Why string instead of Enum? So that we can allow the usage of custom taxonomies in the future
    field :type, :string, default: "category"
    field :children_slugs, {:array, :string}, default: []
  end

  def changeset(model, params) do
    model
    |> cast(params, [:name, :slug, :type, :children_slugs])
    |> validate_required([:name, :slug, :type])
  end
end
