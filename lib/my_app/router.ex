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

  # Route racine "/"
  get "/" do
    html = EEx.eval_file("lib/my_app/templates/home.html.eex", assigns: [name: "Kenneth"])
    send_resp(conn, 200, html)
  end

  forward "/home",     to: MyApp.Controllers.HomeController
  forward "/login",    to: MyApp.Controllers.LoginController
  forward "/register", to: MyApp.Controllers.RegisterController
  forward "/onboarding", to: MyApp.Controllers.OnboardingController

  # ============================================
  # Routes Dashboard (privées)
  # ============================================

  # Dashboard principal
  forward "/dashboard", to: MyApp.Controllers.DashboardController

  # Gestion des pages (CRUD)
  forward "/dashboard/pages", to: MyApp.Controllers.UserPageController

  # Gestion des liens d'une page (CRUD)
  # Note: Les routes avec :page_id sont gérées dans UserLinkController
  forward "/dashboard/pages/:page_id/links", to: MyApp.Controllers.UserLinkController

  # Settings utilisateur (optionnel, si vous gardez ce controller)
  forward "/user/settings", to: MyApp.Controllers.UserSettingsController

  # ============================================
  # Routes publiques - Affichage des pages
  # (DOIT être en dernier pour éviter les conflits)
  # ============================================

  # Affichage public des pages utilisateur
  # /:username ou /:username/:page_slug
  forward "/", to: MyApp.Controllers.PageViewController

  # ============================================
  # 404
  # ============================================

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
