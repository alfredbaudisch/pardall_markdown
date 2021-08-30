defmodule InstaMarkdown.Repo do
  use Ecto.Repo,
    otp_app: :insta_markdown,
    adapter: Ecto.Adapters.Postgres
end
