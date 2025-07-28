# Logger Configuration for River Side Food Court
#
# This file contains logger configuration options that can be imported
# into your environment-specific config files (dev.exs, prod.exs, etc.)
#
# To use this configuration, add the following to your config file:
# import_config "logger_config.exs"

import Config

# Suppress Phoenix LiveView session debug messages
# These messages appear as "[debug] LiveView session was misconfigured..."
# but are actually harmless and don't indicate any real issues
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :vendor_id],
  # Filter out specific debug messages
  filter_default: [
    # Suppress LiveView session misconfiguration debug messages
    {&(&1[:module] == Phoenix.LiveView.Socket and
         &1[:level] == :debug and
         String.contains?(&1[:message], "LiveView session was misconfigured")), :stop}
  ]

# Alternative: Set specific module log levels
# This will suppress ALL debug messages from Phoenix.LiveView.Socket
# config :logger, compile_time_purge_matching: [
#   [module: Phoenix.LiveView.Socket, level_lower_than: :info]
# ]

# Alternative: Increase overall log level (not recommended for development)
# config :logger, level: :info

# For production, you might want more aggressive filtering:
if config_env() == :prod do
  config :logger, :console,
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id],
    # Only log info and above in production
    level: :info
end

# Custom backend for file logging (optional)
# config :logger,
#   backends: [:console, {LoggerFileBackend, :error_log}]
#
# config :logger, :error_log,
#   path: "logs/error.log",
#   level: :error,
#   format: "$date $time $metadata[$level] $message\n",
#   metadata: [:request_id, :user_id, :vendor_id],
#   size_limit: 10_485_760, # 10MB
#   rotate: 5
