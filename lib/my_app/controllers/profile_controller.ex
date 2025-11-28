defmodule MyApp.Controllers.ProfileController do
  use Plug.Router
  alias MyApp.Services.UserLinksStorage
  alias MyApp.Services.UserSettingsStorage

  plug :match
  plug :dispatch

  # Route pour tracker un clic et rediriger
  get "/:username/l/:link_id" do
    link = UserLinksStorage.get_link_by_id(link_id)

    if link && link.active do
      # Incrémenter le compteur de clics
      UserLinksStorage.increment_click(link_id)

      # Rediriger vers l'URL du lien
      conn
      |> put_resp_header("location", link.url)
      |> send_resp(302, "")
    else
      send_resp(conn, 404, "Lien non trouvé")
    end
  end

  # Route pour afficher la page publique du créateur
  get "/:username" do
    username = conn.path_params["username"]

    # Récupérer les settings du user par username
    settings = UserSettingsStorage.get_settings_by_username(username)

    if settings do
      # Récupérer tous les liens du user
      links = UserLinksStorage.get_user_links(settings.user_id)
      |> Enum.filter(&(&1.active))  # Seulement les liens actifs
      |> Enum.sort_by(&(&1.position))

      # Calculer les stats (optionnel)
      total_clicks = Enum.reduce(links, 0, fn link, acc ->
        acc + (link.clicks || 0)
      end)

      html = EEx.eval_file("lib/my_app/templates/profile.html.eex",
        assigns: %{
          username: username,
          bio: settings.bio || "",
          profile_image: settings.profile_image,
          links: links,
          theme: settings.theme || "default",
          primary_color: settings.primary_color || "#3B82F6",
          background_color: settings.background_color || "#FFFFFF",
          button_style: settings.button_style || "rounded",
          total_clicks: total_clicks
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    else
      # Username n'existe pas
      html = EEx.eval_file("lib/my_app/templates/404.html.eex",
        assigns: %{
          message: "Ce profil n'existe pas"
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(404, html)
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
