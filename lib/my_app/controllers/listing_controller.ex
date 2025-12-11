defmodule MyApp.Controllers.ListingController do
  use Plug.Router
  alias MyApp.Services.AnnouncementService
  alias MyApp.Services.TagService

  # Routes:
  # GET  /           → Page d'accueil avec feed d'annonces actives
  #                    Params: ?q=search_query&tags[]=tag1&tags[]=tag2

  plug :match
  plug :dispatch

  get "/" do
    search_query = conn.params["q"] || ""
    selected_tags = conn.params["tags"] || []

    announcements = AnnouncementService.list_active(search_query, selected_tags)
    popular_tags = TagService.get_popular_tags()

    announcements_with_time = Enum.map(announcements, fn ann ->
      Map.put(ann, :time_ago, calculate_time_ago(ann.inserted_at))
    end)

    html = EEx.eval_file("lib/my_app/templates/test_design.html.eex",
      assigns: %{
        announcements: announcements_with_time,
        popular_tags: popular_tags,
        search_query: search_query,
        selected_tags: selected_tags,
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
