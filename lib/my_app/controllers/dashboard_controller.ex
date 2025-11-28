defmodule MyApp.Controllers.DashboardController do
  use Plug.Router
  alias MyApp.Services.UserLinksStorage
  alias MyApp.Services.UserSettingsStorage

  plug :match
  plug :dispatch

  get "/" do
    user_id = get_session(conn, :user_id)
    user_email = get_session(conn, :user_email)

    # Si pas connecté, redirect vers login
    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Récupérer les données du user
      user_settings = UserSettingsStorage.get_settings(user_id) || %{
        username: nil,
        bio: "",
        profile_image: nil,
        theme: "default"
      }

      links = UserLinksStorage.get_user_links(user_id) || []

      # Calculer stats basiques (optionnel pour MVP)
      total_clicks = Enum.reduce(links, 0, fn link, acc ->
        acc + (link.clicks || 0)
      end)

      html = EEx.eval_file("lib/my_app/templates/dashboard.html.eex",
        assigns: %{
          user_email: user_email,
          username: user_settings.username,
          bio: user_settings.bio,
          profile_image: user_settings.profile_image,
          links: links,
          total_links: length(links),
          total_clicks: total_clicks,
          profile_url: if(user_settings.username, do: "/#{user_settings.username}", else: nil)
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end
end
