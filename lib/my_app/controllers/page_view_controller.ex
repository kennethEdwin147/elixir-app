defmodule MyApp.Controllers.PageViewController do
  use Plug.Router
  alias MyApp.Services.UserPageStorage
  alias MyApp.Services.UserLinkStorage
  alias MyApp.Services.UserStorage

  # Routes:
  # GET /:username                       → show_primary (affiche la page principale du user)
  # GET /:username/:page_slug            → show_page (affiche une page spécifique)
  # GET /:username/:page_slug/l/:link_id → track_click (track + redirige vers le lien)

  plug :match
  plug :dispatch

  # Route pour tracker un clic et rediriger
  get "/:username/:page_slug/l/:link_id" do
    username = conn.path_params["username"]
    page_slug = conn.path_params["page_slug"]
    link_id = conn.path_params["link_id"]

    # Récupérer le user par username
    user = UserStorage.get_user_by_username(username)

    if user do
      # Récupérer la page par slug
      page = UserPageStorage.get_page_by_slug(user.id, page_slug)

      if page do
        # Récupérer le lien
        link = UserLinkStorage.get_link_by_id(link_id)

        if link && link.page_id == page.id && link.is_active do
          # Incrémenter le compteur de clics
          UserLinkStorage.increment_click(link_id)

          # Rediriger vers l'URL du lien
          conn
          |> put_resp_header("location", link.url)
          |> send_resp(302, "")
        else
          send_resp(conn, 404, "Lien non trouvé ou inactif")
        end
      else
        send_resp(conn, 404, "Page non trouvée")
      end
    else
      send_resp(conn, 404, "Utilisateur non trouvé")
    end
  end

  # Route pour afficher une page spécifique d'un utilisateur
  get "/:username/:page_slug" do
    username = conn.path_params["username"]
    page_slug = conn.path_params["page_slug"]

    # Récupérer le user par username
    user = UserStorage.get_user_by_username(username)

    if user do
      # Récupérer la page par slug
      page = UserPageStorage.get_page_by_slug(user.id, page_slug)

      if page do
        # Récupérer tous les liens actifs de cette page, triés par position
        links = UserLinkStorage.get_page_links(page.id)
        |> Enum.filter(&(&1.is_active))
        |> Enum.sort_by(&(&1.position))

        # Calculer les stats (optionnel)
        total_clicks = Enum.reduce(links, 0, fn link, acc ->
          acc + (link.clicks_count || 0)
        end)

        html = EEx.eval_file("lib/my_app/templates/public_page.html.eex",
          assigns: %{
            username: username,
            page_slug: page_slug,
            page_title: page.title,
            bio: page.bio || "",
            avatar_url: page.avatar_url,
            links: links,
            theme: page.theme || %{},
            total_clicks: total_clicks
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(200, html)
      else
        # Page n'existe pas
        html = EEx.eval_file("lib/my_app/templates/404.html.eex",
          assigns: %{
            message: "Cette page n'existe pas"
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(404, html)
      end
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

  # Route pour afficher la page principale d'un utilisateur
  get "/:username" do
    username = conn.path_params["username"]

    # Récupérer le user par username
    user = UserStorage.get_user_by_username(username)

    if user do
      # Récupérer la page principale (is_primary = true)
      page = UserPageStorage.get_primary_page(user.id)

      if page do
        # Récupérer tous les liens actifs de cette page, triés par position
        links = UserLinkStorage.get_page_links(page.id)
        |> Enum.filter(&(&1.is_active))
        |> Enum.sort_by(&(&1.position))

        # Calculer les stats (optionnel)
        total_clicks = Enum.reduce(links, 0, fn link, acc ->
          acc + (link.clicks_count || 0)
        end)

        html = EEx.eval_file("lib/my_app/templates/public_page.html.eex",
          assigns: %{
            username: username,
            page_slug: page.slug,
            page_title: page.title,
            bio: page.bio || "",
            avatar_url: page.avatar_url,
            links: links,
            theme: page.theme || %{},
            total_clicks: total_clicks
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(200, html)
      else
        # Aucune page principale définie
        html = EEx.eval_file("lib/my_app/templates/404.html.eex",
          assigns: %{
            message: "Ce profil n'a pas de page principale configurée"
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(404, html)
      end
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
