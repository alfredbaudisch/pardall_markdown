defmodule InstaMarkdown.Content do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  embedded_schema do
    field :type, Ecto.Enum, values: [:html, :text, :image, :audio, :video, :pdf]
    field :path, :string
    field :content, :string
    field :title, :string
    field :slug, :string
    field :url, :string
    timestamps(autogenerate: {NaiveDateTime, :utc_now, 1})
  end

  def changeset(model, params) do
    model
    |> cast(params, [:path, :content, :title, :slug, :url])
  end
end
