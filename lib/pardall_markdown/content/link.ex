defmodule PardallMarkdown.Content.Link do
  @moduledoc """
  This model has many usages in PardallMarkdown:
  - Taxonomies/categories are saved as `Link`. A taxonomy `Link` also has all of its `Post` posts embedded into `:children` (notice that the post content is set to `nil` when the post in emdebbed into a `Link`).
  - Post links for navigation and hierarchisation. A `Post` own `Link` also contains links to the `:previous` and `:next` posts of the content tree.

  Special notes:
  - `:sort_by` and `:sort_order`: the sorting rule to sort a taxonomy's posts. Used only by links of the `type: :taxonomy`.
  - `:index_post`: the parsed `_index.md` file as a `Post`. Can be used when showing the archive page of a taxonomy (alongside the taxonomy `Link.children` posts). Used only by links of the `type: :taxonomy`.
  """

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
    embeds_many :children, PardallMarkdown.Content.Post

    #
    # Taxonomy specific fields
    #
    # how to sort children posts
    field :sort_by, Ecto.Enum, values: [:title, :date, :slug, :position], default: :date
    field :sort_order, Ecto.Enum, values: [:asc, :desc], default: :desc
    # the taxonomy own post/custom page
    embeds_one :index_post, PardallMarkdown.Content.Post
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
      :position,
      :sort_by,
      :sort_order
    ])
    |> validate_required([
      :title,
      :slug,
      :type,
      :level,
      :parents,
      :position,
      :sort_by,
      :sort_order
    ])
    |> cast_embed(:children)
    |> cast_embed(:previous)
    |> cast_embed(:next)
    |> cast_embed(:index_post)
  end
end
