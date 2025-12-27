defmodule MyApp.Application do
  use Application

  @impl true

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      # Conditionnellement démarrer le serveur
      maybe_start_server()
    ]
    |> List.flatten()  # Flatten car maybe_start_server peut retourner []

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Nouvelle fonction
  defp maybe_start_server do
    if Application.get_env(:my_app, :start_http_server, true) do
      [
        {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4000]}
      ]
    else
      []
    end
  end
end
