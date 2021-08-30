defmodule LiveMarkdown.Content.Repository.Utils do
  alias LiveMarkdown.Content
  alias Ecto.Changeset

  def put_timestamps(changeset, %Content{inserted_at: nil}) do
    now = NaiveDateTime.utc_now()

    changeset
    |> Changeset.put_change(:inserted_at, now)
    |> Changeset.put_change(:updated_at, now)
  end

  def put_timestamps(changeset, _model) do
    changeset
    |> Changeset.put_change(:updated_at, NaiveDateTime.utc_now())
  end
end
