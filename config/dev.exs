use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console,
  format: "$time [$level][$metadata] $message\n",
  metadata: [:mfa]
