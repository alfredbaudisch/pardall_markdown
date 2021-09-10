use Mix.Config

# Configure your database
#

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :koda_markdown, KodaMarkdownWeb.Endpoint,
  http: [port: 4002],
  server: false

config :koda_markdown, KodaMarkdown.Content,
  root_path: "./test/content",
  static_assets_folder_name: "static",
  cache_name: :content_cache,
  index_cache_name: :content_index_cache,
  site_name: "KodaMarkdown"

# Print only warnings and errors during test
config :logger, level: :warn
