# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :pardall_markdown, PardallMarkdown.Content,
  # Check the README for instructions regarding the configuration
  root_path: "./sample_content",
  static_assets_path: "./sample_content/static",
  cache_name: :content_cache,
  index_cache_name: :content_index_cache,
  recheck_pending_file_events_interval: 5_000,
  content_tree_display_home: false,
  convert_internal_links_to_live_links: true,
  notify_content_reloaded: fn -> :ok end,
  is_markdown_metadata_required: true,
  is_content_draft_by_default: true,
  metadata_parser: PardallMarkdown.MetadataParser.ElixirMap,
  # Git repository to watch and automatically fetch content from, leave "" or nil to not
  # get content from a repository.
  # Available sample content repo: "https://github.com/alfredbaudisch/pardall_markdown_sample_content",
  remote_repository_url: "https://github.com/alfredbaudisch/pardall_markdown_sample_content",
  remote_repository_local_path: "./sample_content",
  recheck_pending_remote_events_interval: 15_000

config :pardall_markdown, PardallMarkdown.MetadataParser.JoplinNote,
  metadata_parser_after_title: PardallMarkdown.MetadataParser.ElixirMap

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :mfa]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
