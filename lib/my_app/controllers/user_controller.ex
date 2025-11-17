defmodule MyApp.Controllers.UserController do
  @moduledoc """
  Gère le profil utilisateur et ses wraps.
  """

  use Plug.Router

  plug :match
  plug :dispatch

  @doc """
  Affiche le dashboard général de l'utilisateur.
  """
  get "/dashboard" do
    html = EEx.eval_file("lib/my_app/templates/dashboard.html.eex",
      assigns: [name: "Kenneth"]
    )
    send_resp(conn, 200, html)
  end

  @doc """
  Affiche tous les wraps de l'utilisateur connecté.
  """
  get "/wraps" do
    # TODO: Récupérer user_id depuis session
    # user_id = get_session(conn, :user_id)

    # TODO: Charger wraps depuis DB/filesystem
    # Pour l'instant, exemple statique
    wraps = [
      %{id: "abc123", created_at: "2025-11-15", template: "classic"},
      %{id: "def456", created_at: "2025-11-10", template: "minimal"}
    ]

    html = EEx.eval_file("lib/my_app/templates/user/wraps.html.eex",
      assigns: %{
        wraps: wraps
      }
    )

    send_resp(conn, 200, html)
  end

  @doc """
  Permet à un utilisateur de claim un wrap anonymous.
  """
  post "/wraps/:id/claim" do
    wrap_id = conn.path_params["id"]

    # TODO: Récupérer user_id depuis session
    # TODO: Associer wrap_id au user_id

    conn
    |> put_resp_header("location", "/user/wraps")
    |> send_resp(302, "")
  end
end
