defmodule LiveMarkdown.Repo do
  use Ecto.Repo,
    otp_app: :live_markdown,
    adapter: Ecto.Adapters.Postgres
end
