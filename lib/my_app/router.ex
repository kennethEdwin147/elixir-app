defmodule MyApp.Router do
  use Plug.Router

  plug Plug.Logger

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
    secure: false, # <--- Uniquement si tu es en HTTPS
    http_only: true, # <--- Empêche le JS de lire ton cookie (déjà par défaut, mais bien de le savoir)
    secret_key_base: "votre-clé-secrète-très-longue-et-sécurisée-au-moins-64-caractères",
    signing_salt: "signing_salt"

  plug :fetch_session
  plug MyApp.Plugs.LoadUser  # ← AJOUTE CETTE LIGNE

  if Application.get_env(:my_app, :csrf_protection, true) do
    plug Plug.CSRFProtection
  end

  plug :put_secure_browser_headers
  plug :match
  plug :dispatch

  # ============================================
  # Routes spécifiques (AVANT les routes génériques)
  # ============================================

  forward "/auth",         to: MyApp.Controllers.AuthController
  forward "/onboarding",   to: MyApp.Controllers.OnboardingController
  forward "/g",            to: MyApp.Controllers.GameFeedController

  # ============================================
  # Route racine (EN DERNIER)
  # ============================================

  get "/" do
    # Redirige vers /g/valorant ou affiche home
    conn
    |> put_resp_header("location", "/g/valorant")
    |> send_resp(302, "")
  end

  # OU si tu veux vraiment forward:
  # forward "/", to: MyApp.Controllers.HomeController

  # ============================================
  # 404
  # ============================================

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp put_secure_browser_headers(conn, _opts) do
    conn
    |> put_resp_header("x-frame-options", "SAMEORIGIN")
    |> put_resp_header("x-xss-protection", "1; mode=block")
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("content-security-policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data: https:;")
  end
end
