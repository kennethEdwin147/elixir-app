defmodule MyApp.Controllers.ConnectionController do
  use Plug.Router

  alias MyApp.Contexts.{Connection, Game}
  alias MyApp.Repo
  alias MyApp.Schemas.User

  plug :match
  plug :dispatch

  # ============================================================================
  # POST /connections/request
  # Envoyer une demande "Ça m'intéresse"
  # ============================================================================

  post "/request" do
    current_user = conn.assigns[:current_user]
    params = conn.body_params

    case Connection.send_request(%{
           requester_id: current_user.id,
           target_id: params["target_id"],
           game_id: params["game_id"],
           message: params["message"]
         }) do
      {:ok, _request} ->
        game = Repo.get!(MyApp.Schemas.Game, params["game_id"])

        conn
        |> put_session(:flash_success, "Demande envoyée!")
        |> put_resp_header("location", "/discover/#{game.slug}")
        |> send_resp(302, "")

      {:error, :self_request} ->
        conn
        |> put_session(:flash_error, "Tu ne peux pas t'envoyer une demande")
        |> put_resp_header("location", "/discover/valorant")
        |> send_resp(302, "")

      {:error, :already_connected} ->
        conn
        |> put_session(:flash_info, "Vous êtes déjà connectés")
        |> put_resp_header("location", "/connections")
        |> send_resp(302, "")

      {:error, :request_exists} ->
        conn
        |> put_session(:flash_info, "Demande déjà envoyée")
        |> put_resp_header("location", "/discover/valorant")
        |> send_resp(302, "")

      {:error, _} ->
        conn
        |> put_session(:flash_error, "Erreur lors de l'envoi de la demande")
        |> put_resp_header("location", "/discover/valorant")
        |> send_resp(302, "")
    end
  end

  # ============================================================================
  # GET /connections/requests
  # Afficher les demandes reçues en attente
  # ============================================================================

  get "/requests" do
    current_user = conn.assigns[:current_user]

    # Pour MVP: hardcode Valorant
    game = Game.get_by_slug("valorant")

    unless game do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(404, "<h1>Game not found</h1>")
    else
      # Récupérer les demandes reçues en attente
      requests = Connection.list_received_requests(current_user.id, game.id, status: "pending")

      flash_success = get_session(conn, :flash_success)
      flash_error = get_session(conn, :flash_error)
      flash_info = get_session(conn, :flash_info)

      html =
        EEx.eval_file(
          "lib/my_app/templates/connections/requests.html.eex",
          assigns: %{
            current_user: current_user,
            requests: requests,
            game: game,
            flash_success: flash_success,
            flash_error: flash_error,
            flash_info: flash_info
          }
        )

      conn
      |> delete_session(:flash_success)
      |> delete_session(:flash_error)
      |> delete_session(:flash_info)
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  # ============================================================================
  # POST /connections/requests/:id/accept
  # Accepter une demande de connexion
  # ============================================================================

  post "/requests/:id/accept" do
    current_user = conn.assigns[:current_user]
    request_id = conn.path_params["id"]

    case Connection.get_request(request_id) do
      nil ->
        conn
        |> put_session(:flash_error, "Demande introuvable")
        |> put_resp_header("location", "/connections/requests")
        |> send_resp(302, "")

      request ->
        # Vérifier que le current_user est bien le destinataire
        if request.target_id != current_user.id do
          conn
          |> put_session(:flash_error, "Non autorisé")
          |> put_resp_header("location", "/")
          |> send_resp(302, "")
        else
          case Connection.accept_request(request_id) do
            {:ok, _connection} ->
              conn
              |> put_session(
                :flash_success,
                "Connexion acceptée! Vous pouvez maintenant jouer ensemble"
              )
              |> put_resp_header("location", "/connections")
              |> send_resp(302, "")

            {:error, :not_found} ->
              conn
              |> put_session(:flash_error, "Demande introuvable")
              |> put_resp_header("location", "/connections/requests")
              |> send_resp(302, "")

            {:error, :already_accepted} ->
              conn
              |> put_session(:flash_info, "Demande déjà acceptée")
              |> put_resp_header("location", "/connections")
              |> send_resp(302, "")

            {:error, _} ->
              conn
              |> put_session(:flash_error, "Erreur lors de l'acceptation")
              |> put_resp_header("location", "/connections/requests")
              |> send_resp(302, "")
          end
        end
    end
  end

  # ============================================================================
  # POST /connections/requests/:id/decline
  # Décliner une demande de connexion
  # ============================================================================

  post "/requests/:id/decline" do
    current_user = conn.assigns[:current_user]
    request_id = conn.path_params["id"]

    case Connection.get_request(request_id) do
      nil ->
        conn
        |> put_session(:flash_error, "Demande introuvable")
        |> put_resp_header("location", "/connections/requests")
        |> send_resp(302, "")

      request ->
        # Vérifier que le current_user est bien le destinataire
        if request.target_id != current_user.id do
          conn
          |> put_session(:flash_error, "Non autorisé")
          |> put_resp_header("location", "/")
          |> send_resp(302, "")
        else
          case Connection.decline_request(request_id) do
            {:ok, _} ->
              conn
              |> put_session(:flash_info, "Demande déclinée")
              |> put_resp_header("location", "/connections/requests")
              |> send_resp(302, "")

            {:error, :not_found} ->
              conn
              |> put_session(:flash_error, "Demande introuvable")
              |> put_resp_header("location", "/connections/requests")
              |> send_resp(302, "")

            {:error, _} ->
              conn
              |> put_session(:flash_error, "Erreur lors du refus")
              |> put_resp_header("location", "/connections/requests")
              |> send_resp(302, "")
          end
        end
    end
  end

  # ============================================================================
  # GET /connections
  # Afficher les connexions établies
  # ============================================================================

  get "/" do
    current_user = conn.assigns[:current_user]

    # Pour MVP: hardcode Valorant
    game = Game.get_by_slug("valorant")

    unless game do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(404, "<h1>Game not found</h1>")
    else
      # Récupérer les connexions
      connections = Connection.list_connections(current_user.id, game.id)

      # Préparer les données avec l'autre user
      connections_with_users =
        Enum.map(connections, fn connection ->
          other_user_id =
            if connection.user_id_1 == current_user.id do
              connection.user_id_2
            else
              connection.user_id_1
            end

          other_user = Repo.get!(User, other_user_id)
          {connection, other_user}
        end)

      flash_success = get_session(conn, :flash_success)
      flash_error = get_session(conn, :flash_error)
      flash_info = get_session(conn, :flash_info)

      html =
        EEx.eval_file(
          "lib/my_app/templates/connections/index.html.eex",
          assigns: %{
            current_user: current_user,
            connections: connections_with_users,
            game: game,
            flash_success: flash_success,
            flash_error: flash_error,
            flash_info: flash_info,
            format_date: &MyApp.Views.ConnectionsView.format_date/1
          }
        )

      conn
      |> delete_session(:flash_success)
      |> delete_session(:flash_error)
      |> delete_session(:flash_info)
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end
end
