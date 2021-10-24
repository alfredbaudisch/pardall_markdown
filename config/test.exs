use Mix.Config

config :pardall_markdown, PardallMarkdown.Content,
  root_path: "./test/content",
  static_assets_path: "./test/content/static",
  cache_name: :content_cache,
  index_cache_name: :content_index_cache,
  is_markdown_metadata_required: true,
  remote_repository_url: ""

# Print only warnings and errors during test
config :logger, level: :warn
