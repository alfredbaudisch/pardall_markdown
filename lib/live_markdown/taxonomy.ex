defmodule LiveMarkdown.Taxonomy do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :binary, autogenerate: false}
  @foreign_key_type :slug
  embedded_schema do
    field :name, :string

    # Why string instead of Enum? So that we can allow the usage of custom taxonomies in the future
    field :type, :string, default: "category"
    field :level, :integer, default: 1
    field :parents, {:array, :string}, default: ["/"]
    embeds_many :children, LiveMarkdown.Post
  end

  def changeset(model, params) do
    model
    |> cast(params, [:name, :slug, :type, :level, :parents])
    |> validate_required([:name, :slug, :type, :level, :parents])
    |> cast_embed(:children)
  end
end
