import Config

# Import environment specific config
# This will load:
# - config/dev.exs in dev mode (default)
# - config/test.exs in test mode
import_config "#{config_env()}.exs"
