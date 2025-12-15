defmodule MyApp.Router do
  use Plug.Router

  plug Plug.Logger

  # Sert les fichiers statiques
  plug Plug.Static,
    at: "/static",
    from: {:my_app, "priv/static"}

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.Session,
    store: :cookie,
    key: "_my_app_session",
    secret_key_base: "votre-clé-secrète-très-longue-et-sécurisée-au-moins-64-caractères",
    signing_salt: "signing_salt"

  plug :fetch_session   # <-- indispensable

  plug :match
  plug :dispatch

  # ============================================
  # Routes publiques (home, auth)
  # ============================================

    get "/test-design" do
      html = EEx.eval_file("lib/my_app/templates/test_design.html.eex", assigns: %{})

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end

    get "/create-announcement" do
      html = EEx.eval_file("lib/my_app/templates/test_modal.html.eex", assigns: %{})

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end

  forward "/home",     to: MyApp.Controllers.HomeController
  forward "/login",    to: MyApp.Controllers.LoginController
  forward "/register", to: MyApp.Controllers.RegisterController
  forward "/onboarding", to: MyApp.Controllers.OnboardingController

  forward "/listing", to: MyApp.Controllers.ListingController

  forward "/announcements", to: MyApp.Controllers.AnnouncementController
  forward "/search", to: MyApp.Controllers.SearchController

  # ============================================
  # Routes Dashboard (privées)
  # ============================================
\
  # Settings utilisateur (optionnel, si vous gardez ce controller)
  forward "/user/settings", to: MyApp.Controllers.UserSettingsController

    # Route racine "/"
  forward "/", to: MyApp.Controllers.ListingController

  # ============================================
  # 404
  # ============================================

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
