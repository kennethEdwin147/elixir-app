import Config

# Configure test database (MariaDB)
config :my_app, MyApp.Repo,
  database: "my_app_test",
  username: "root",
  password: "kenneth",
  hostname: "localhost",
  port: 3306,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# Dire à Ecto quels Repos existent
config :my_app, ecto_repos: [MyApp.Repo]

# Reduce bcrypt rounds for faster tests
config :bcrypt_elixir, :log_rounds, 4

# Print only warnings and errors during test
config :logger, level: :warning

# Disable CSRF for tests
config :plug, :validate_header_keys_during_test, false

# Disable CSRF protection for unit tests
config :my_app, :csrf_protection, false

# À la fin du fichier, ajoute:

# Don't start HTTP server during tests
config :my_app, start_http_server: false
