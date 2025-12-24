defmodule MyApp.Controllers.ListingController do
  use Plug.Router
  alias MyApp.Services.AnnouncementService
  alias MyApp.Services.TagService
  alias MyApp.Services.GameCatalogService

  # Routes:
  # GET  /           → Page d'accueil avec feed d'annonces actives
  #                    Params: ?q=search_query&tags[]=tag1&tags[]=tag2

  plug :match
  plug :dispatch

   get "/favicon.ico" do
    send_resp(conn, 204, "")
  end

  get "/" do
    search_query = trim_param(conn.params["q"])
    selected_tags = conn.params["tags"] || []
    selected_game = trim_param(conn.params["game"])

    IO.inspect(conn.params, label: "🔍 PARAMS REÇUS")

    # Passer game filter au service
    announcements = AnnouncementService.list_active(
      search_query,
      selected_tags,
      selected_game  # ← NOUVEAU
    )

     # ========================================
    # DEBUG: Voir les valeurs extraites
    # ========================================
    IO.inspect(search_query, label: "🔍 SEARCH QUERY")
    IO.inspect(selected_tags, label: "🔍 SELECTED TAGS")
    IO.inspect(selected_game, label: "🔍 SELECTED GAME")

        IO.inspect(length(announcements), label: "🔍 NOMBRE ANNONCES RETOURNÉES")


    popular_tags = TagService.get_popular_tags()
    all_games = GameCatalogService.all()

    announcements_with_time = Enum.map(announcements, fn ann ->
      Map.put(ann, :time_ago, calculate_time_ago(ann.inserted_at))
    end)

    html = EEx.eval_file("lib/my_app/templates/test_design.html.eex",
      assigns: %{
        announcements: announcements_with_time,
        popular_tags: popular_tags,
        all_games: all_games,
        search_query: search_query,
        selected_tags: selected_tags,
        selected_game: selected_game,
        user_id: get_session(conn, :user_id),
        has_results: length(announcements_with_time) > 0  # ← Pour afficher "Aucune annonce"
      }
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================


    # Trim string ou retourne nil si vide
  defp trim_param(nil), do: nil
  defp trim_param(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  # Calcule le temps écoulé depuis la création
  defp calculate_time_ago(naive_datetime) do
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 10 -> "à l'instant"
      diff < 60 -> "#{diff}s"
      diff < 3600 -> "#{div(diff, 60)}min"
      diff < 86400 -> "#{div(diff, 3600)}h"
      diff < 2592000 -> "#{div(diff, 86400)}j"  # < 30 jours
      true -> "#{div(diff, 2592000)}mois"
    end
  end
end
