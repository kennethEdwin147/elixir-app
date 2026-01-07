defmodule MyApp.Controllers.ProfileDiscoveryController do
  use Plug.Router

  alias MyApp.Contexts.{Game, Profile}
  alias MyApp.Matching
  alias MyApp.Views.ProfileDiscoveryView

  plug :match
  plug :dispatch

  # ============================================================================
  # GET /discover/:game
  # Feed principal de découverte de profils
  # ============================================================================

  get "/" do
    current_user = conn.assigns[:current_user]
    game_slug = conn.path_params["game"]

    # Redirect si pas connecté
    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      case Game.get_by_slug(game_slug) do
        nil ->
          conn
          |> put_resp_content_type("text/html")
          |> send_resp(404, "<h1>Game not found</h1>")

        game ->
          # Vérifier si user a un profil pour ce jeu
          unless Profile.has_profile_for_game?(current_user.id, game.id) do
            # Pas de profil → redirect vers onboarding
            conn
            |> put_resp_header("location", "/onboarding/#{game_slug}")
            |> send_resp(302, "")
          else
            # Récupérer les matchs du jour
            matches = Matching.daily_matches(current_user, game.id)

            # Si aucun match disponible
            if Enum.empty?(matches) do
              html = """
              <!DOCTYPE html>
              <html>
              <head><title>Aucun profil disponible</title></head>
              <body>
                <h1>Aucun profil compatible trouvé</h1>
                <p>Reviens demain pour découvrir de nouveaux joueurs !</p>
                <a href="/">← Retour à l'accueil</a>
              </body>
              </html>
              """

              conn
              |> put_resp_content_type("text/html", "utf-8")
              |> send_resp(200, html)
            else
              # Récupérer l'index depuis query params (défaut: 0)
              current_index = String.to_integer(conn.query_params["index"] || "0")
              current_index = max(0, min(current_index, length(matches) - 1))

              current_match = Enum.at(matches, current_index)

              # Charger le template selon le jeu
              template_path = "lib/my_app/templates/profile_discovery/#{game_slug}.html.eex"

              html =
                EEx.eval_file(
                  template_path,
                  assigns: %{
                    current_user: current_user,
                    game: game,
                    matches: matches,
                    current_match: current_match,
                    current_index: current_index,
                    total: length(matches),
                    get_agent: &ProfileDiscoveryView.get_agent/1,
                    format_availabilities: &ProfileDiscoveryView.format_availabilities/1
                  }
                )

              conn
              |> put_resp_content_type("text/html", "utf-8")
              |> send_resp(200, html)
            end
          end
      end
    end
  end

  # ============================================================================
  # GET /discover/:game/profiles/:id
  # Affiche un profil détaillé
  # ============================================================================

  get "/profiles/:id" do
    current_user = conn.assigns[:current_user]
    game_slug = conn.path_params["game"]
    profile_id = conn.path_params["id"]

    # Redirect si pas connecté
    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      case Game.get_by_slug(game_slug) do
        nil ->
          conn
          |> put_resp_content_type("text/html")
          |> send_resp(404, "<h1>Game not found</h1>")

        game ->
          case Profile.get_profile_with_details(profile_id) do
            nil ->
              conn
              |> put_resp_content_type("text/html")
              |> send_resp(404, "<h1>Profile not found</h1>")

            profile ->
              # Vérifier que le profil appartient au bon jeu
              if profile.game_id != game.id do
                conn
                |> put_resp_content_type("text/html")
                |> send_resp(404, "<h1>Profile not found</h1>")
              else
                html =
                  EEx.eval_file(
                    "lib/my_app/templates/profile_discovery/show.html.eex",
                    assigns: %{
                      current_user: current_user,
                      game: game,
                      profile: profile,
                      get_agent: &ProfileDiscoveryView.get_agent/1,
                      format_availabilities: &ProfileDiscoveryView.format_availabilities/1
                    }
                  )

                conn
                |> put_resp_content_type("text/html", "utf-8")
                |> send_resp(200, html)
              end
          end
      end
    end
  end
end
