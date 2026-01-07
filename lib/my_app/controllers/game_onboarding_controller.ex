defmodule MyApp.Controllers.GameOnboardingController do
  use Plug.Router

  alias MyApp.Contexts.{Game, Profile}
  alias MyApp.Games.Valorant

  plug :match
  plug :dispatch

  # ============================================================================
  # GET /onboarding/:game
  # Affiche le formulaire d'onboarding pour un jeu
  #
  # Template dynamique basé sur le slug du jeu:
  #   - /onboarding/valorant → valorant.html.eex
  #   - /onboarding/lol → lol.html.eex
  #   - /onboarding/apex → apex.html.eex
  # ============================================================================

  get "/:game" do
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
          # Vérifier si user a déjà un profile pour ce jeu
          if Profile.has_profile_for_game?(current_user.id, game.id) do
            # Déjà un profile → redirect vers le feed du jeu
            conn
            |> put_resp_header("location", "/#{game_slug}")
            |> send_resp(302, "")
          else
            # Pas de profile → afficher formulaire spécifique au jeu
            template_path = "lib/my_app/templates/game_onboarding/#{game_slug}.html.eex"

            html = EEx.eval_file(
              template_path,
              assigns: %{
                current_user: current_user,
                game: game,
                ranks: Valorant.ranks(),
                agents: Valorant.agents(),
                regions: Valorant.regions(),
                playstyles: Valorant.playstyles(),
                age_ranges: Valorant.age_ranges(),
                vibe_tags: Valorant.vibe_tags(),
                errors: nil
              }
            )

            conn
            |> put_resp_content_type("text/html", "utf-8")
            |> send_resp(200, html)
          end
      end
    end
  end

  # ============================================================================
  # POST /onboarding/:game
  # Crée le profile pour le jeu
  #
  # En cas d'erreur, re-render le template dynamique basé sur le slug:
  #   - /onboarding/valorant → valorant.html.eex
  #   - /onboarding/lol → lol.html.eex
  #   - /onboarding/apex → apex.html.eex
  # ============================================================================

  post "/:game" do
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
          params = conn.body_params

          # Créer le profile avec game_specific_data
          case Profile.create_with_game_data(current_user, game.id, params) do
            {:ok, _profile} ->
              # Success → redirect vers home avec message
              conn
              |> put_session(:flash_success, "Profil créé! Le feed arrive bientôt...")
              |> put_resp_header("location", "/")
              |> send_resp(302, "")

            {:error, changeset} ->
              # Erreur → re-render formulaire avec errors
              template_path = "lib/my_app/templates/game_onboarding/#{game_slug}.html.eex"

              html = EEx.eval_file(
                template_path,
                assigns: %{
                  current_user: current_user,
                  game: game,
                  ranks: Valorant.ranks(),
                  agents: Valorant.agents(),
                  regions: Valorant.regions(),
                  playstyles: Valorant.playstyles(),
                  age_ranges: Valorant.age_ranges(),
                  vibe_tags: Valorant.vibe_tags(),
                  errors: changeset.errors
                }
              )

              conn
              |> put_resp_content_type("text/html", "utf-8")
              |> send_resp(400, html)
          end
      end
    end
  end
end
