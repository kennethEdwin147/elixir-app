# lib/my_app/controllers/search_controller.ex
defmodule MyApp.Controllers.SearchController do
  use Plug.Router
  alias MyApp.Services.TagService
  alias MyApp.Services.AnnouncementService

  # Routes:
  # GET  /search/tags                  → API JSON pour autocomplétion tags
  #                                       Params: ?q=search_query
  # GET  /search/announcements         → API HTML pour filtrage temps réel
  #                                       Params: ?q=search_query&tags[]=tag1

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  # API pour autocomplétion des tags
  get "/tags" do
    query = conn.params["q"] || ""

    suggestions = TagService.search_tags(query)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{suggestions: suggestions}))
  end

  # API pour filtrer annonces en temps réel (optionnel)
  get "/announcements" do
    search_query = conn.params["q"] || ""
    tags = conn.params["tags"] || []

    announcements = AnnouncementService.list_active(search_query, tags)

    # Render partiel HTML ou JSON selon besoin
    html = EEx.eval_string("""
    <%= for announcement <- @announcements do %>
      <%= EEx.eval_file("lib/my_app/templates/partials/announcement_card.html.eex",
          assigns: %{announcement: announcement, user_id: @user_id}) %>
    <% end %>
    """, assigns: %{announcements: announcements, user_id: get_session(conn, :user_id)})

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end
end
