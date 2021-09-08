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
    field :priority, :integer, default: 0
    embeds_one :previous, __MODULE__
    embeds_one :next, __MODULE__
    embeds_many :children, LiveMarkdown.Post

    #
    # Taxonomy specific fields
    #
    # how to sort children posts
    field :sort_by, Ecto.Enum, values: [:title, :date, :slug, :priority], default: :date
    field :sort_order, Ecto.Enum, values: [:asc, :desc], default: :desc
    # the taxonomy own post/custom index page
    embeds_one :index_post, LiveMarkdown.Post
  end

  def changeset(model, params) do
    model
    |> cast(params, [
      :title,
      :slug,
      :type,
      :level,
      :parents,
      :custom_type,
      :sort_by,
      :sort_order,
      :priority
    ])
    |> validate_required([:title, :slug, :type, :level, :parents])
    |> cast_embed(:children)
    |> cast_embed(:previous)
    |> cast_embed(:next)
    |> cast_embed(:index_post)
  end

  def default_sort_by, do: :date
  def default_sort_order, do: :desc
end
