defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Démarrer le Repo Ecto
      MyApp.Repo,

      # Démarrer le serveur web Cowboy
      {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
