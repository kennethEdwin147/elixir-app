import Config

# Configuration de la base de données DEV
config :my_app, MyApp.Repo,
  database: "my_app_dev",
  username: "root",
  password: "kenneth",
  hostname: "localhost",
  port: 3306

# Dire à Ecto quels Repos existent
config :my_app, ecto_repos: [MyApp.Repo]
