# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :pardall_markdown, PardallMarkdown.Content,
  # This can be any relative or absolute path, including outside of the application,
  # which is actually, the main use case for PardallMarkdown
  root_path: "/home/alfredbaudisch/Documents/content",
  static_assets_folder_name: "static",
  cache_name: :content_cache,
  index_cache_name: :content_index_cache,
  # Site name to be appened into page titles
  site_name: "Pardall Markdown",
  recheck_pending_file_events_interval: 10_000,
  content_tree_display_home: false,
  convert_internal_links_to_live_links: true,
  notify_content_reloaded: fn -> :ok end

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :mfa]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
