use Mix.Config

config :pardall_markdown, PardallMarkdown.Content,
  root_path: "./test/content",
  static_assets_folder_name: "static",
  cache_name: :content_cache,
  index_cache_name: :content_index_cache

# Print only warnings and errors during test
config :logger, level: :warn
