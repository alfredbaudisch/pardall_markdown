use Mix.Config

# Configure your database
#

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pardall_markdown, PardallMarkdownWeb.Endpoint,
  http: [port: 4002],
  server: false

config :pardall_markdown, PardallMarkdown.Content,
  root_path: "./test/content",
  static_assets_folder_name: "static",
  cache_name: :content_cache,
  index_cache_name: :content_index_cache,
  site_name: "PardallMarkdown"

# Print only warnings and errors during test
config :logger, level: :warn
