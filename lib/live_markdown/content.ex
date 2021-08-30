defmodule LiveMarkdown.Content do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  embedded_schema do
    field :type, Ecto.Enum, values: [:post, :image, :audio, :video, :pdf]
    field :path, :string
    field :content, :string
    field :title, :string
    field :slug, :string
    field :url, :string
    field :date, :utc_datetime
    timestamps(autogenerate: {DateTime, :utc_now, 1})
  end

  def changeset(model, params) do
    model
    |> cast(params, [:path, :content, :title, :slug, :date, :url])
  end
end
