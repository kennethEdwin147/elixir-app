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

  # Route racine "/"
  get "/" do
    html = EEx.eval_file("lib/my_app/templates/index.html.eex", assigns: [name: "Kenneth"])
    send_resp(conn, 200, html)
  end

  forward "/home",     to: MyApp.Controllers.HomeController
  forward "/login",    to: MyApp.Controllers.LoginController
  forward "/register", to: MyApp.Controllers.RegisterController

  forward "/dashboard", to: MyApp.Controllers.DashboardController
  forward "/user/links", to: MyApp.Controllers.UserLinksController
  forward "/user/settings", to: MyApp.Controllers.UserSettingsController

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
