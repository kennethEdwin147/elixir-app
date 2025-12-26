defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # 1. Démarrer le Repo Ecto (Indispensable pour le worker)
      MyApp.Repo,

      # 2. Ton nettoyeur automatique (GenServer)
      MyApp.Workers.CleanupWorker,

      # 3. Démarrer le serveur web Cowboy
      {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4000]}
    ]

    # La stratégie :one_for_one signifie que si un enfant plante,
    # seul cet enfant est redémarré.
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
