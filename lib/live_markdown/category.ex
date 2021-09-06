defmodule LiveMarkdown.Category do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :binary, autogenerate: false}
  @foreign_key_type :slug
  embedded_schema do
    field :name, :string
  end

  def changeset(model, params) do
    model
    |> cast(params, [:name, :slug])
    |> validate_required([:name, :slug])
  end
end
