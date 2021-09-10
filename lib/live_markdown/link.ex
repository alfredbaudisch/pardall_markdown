defmodule LiveMarkdown.Link do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:slug, :binary, autogenerate: false}
  @foreign_key_type :slug
  embedded_schema do
    field :title, :string
    field :type, Ecto.Enum, values: [:post, :taxonomy], default: :taxonomy
    field :custom_type, :string, default: nil
    field :level, :integer, default: 1
    field :parents, {:array, :string}, default: ["/"]
    field :position, :integer, default: 0
    embeds_one :previous, __MODULE__
    embeds_one :next, __MODULE__
    embeds_many :children, LiveMarkdown.Post
    # the taxonomy own post/custom page
    embeds_one :index_post, LiveMarkdown.Post
  end

  def changeset(model, params) do
    model
    |> cast(params, [:title, :slug, :type, :level, :parents, :custom_type, :position])
    |> validate_required([:title, :slug, :type, :level, :parents])
    |> cast_embed(:children)
    |> cast_embed(:previous)
    |> cast_embed(:next)
    |> cast_embed(:index_post)
  end
end
