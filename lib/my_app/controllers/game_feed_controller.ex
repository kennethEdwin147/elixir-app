defmodule MyApp.Controllers.GameFeedController do
  use Plug.Router
  require EEx

  alias MyApp.Services.{AnnouncementService, GameCatalogService}

  plug :match
  plug :dispatch

  # Page feed d'un jeu spécifique
  get "/:slug" do
    slug = conn.params["slug"]

    # Vérifier que le jeu existe
    case GameCatalogService.get_by_slug(slug) do
      nil ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "<h1>Game not found</h1><p>The game '#{slug}' doesn't exist.</p>")

      game ->
        # Récupérer les annonces pour ce jeu
        announcements = AnnouncementService.list_by_game(slug)

        # Stats du jeu
        stats = GameCatalogService.get_stats(slug)

        # Render template
        html = EEx.eval_file("lib/my_app/templates/game_feed.html.eex",
          assigns: %{
            game: game,
            announcements: announcements,
            stats: stats,
            user_id: get_session(conn, :user_id),
            all_games: GameCatalogService.all()
          }
        )

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, html)
    end
  end
end
