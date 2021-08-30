defmodule InstaMarkdown.Content do
  use InstaMarkdown.Schema

  embedded_schema do
    field :path, :string
    field :content, :string
    field :title, :string
    field :slug, :string
    field :url, :string
    timestamps()
  end

  def changeset(model, params) do
    model
    |> cast(params, [:path, :content, :title, :slug, :url])
  end
end
