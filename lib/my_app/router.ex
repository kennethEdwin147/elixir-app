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


  # ========================================
  # PLUGS DE SÉCURITÉ (entre match et dispatch)
  # ========================================
  plug MyApp.Plugs.RequireOnboarding    # ← AJOUTE ICI


  plug :dispatch

  # ============================================
  # Routes spécifiques (AVANT les routes génériques)
  # ============================================

  forward "/auth",         to: MyApp.Controllers.AuthController

  # Onboarding de base (username, display_name)
  get "/profile-setup" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      if current_user.onboarding_completed do
        conn
        |> put_resp_header("location", "/")
        |> send_resp(302, "")
      else
        suggested_username =
          current_user.email
          |> String.split("@")
          |> List.first()
          |> String.replace(~r/[^a-zA-Z0-9_-]/, "")
          |> String.slice(0..19)

        html = EEx.eval_file(
          "lib/my_app/templates/onboarding/form.html.eex",
          assigns: %{
            current_user: current_user,
            suggested_username: suggested_username,
            error_msg: nil
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(200, html)
      end
    end
  end

  post "/profile-setup" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      params = conn.body_params

      case current_user
           |> MyApp.Schemas.User.onboarding_changeset(params)
           |> MyApp.Repo.update() do
        {:ok, _updated_user} ->
          conn
          |> put_session(:flash_success, "Bienvenue #{params["display_name"]} ! 👋")
          |> put_resp_header("location", "/")
          |> send_resp(302, "")

        {:error, changeset} ->
          error_msg =
            changeset.errors
            |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
            |> Enum.join(", ")

          suggested_username =
            current_user.email
            |> String.split("@")
            |> List.first()
            |> String.replace(~r/[^a-zA-Z0-9_-]/, "")
            |> String.slice(0..19)

          html = EEx.eval_file(
            "lib/my_app/templates/onboarding/form.html.eex",
            assigns: %{
              current_user: current_user,
              suggested_username: suggested_username,
              error_msg: error_msg
            }
          )

          conn
          |> put_resp_content_type("text/html", "utf-8")
          |> send_resp(400, html)
      end
    end
  end

  # Onboarding par jeu (profils spécifiques)
  forward "/onboarding",   to: MyApp.Controllers.GameOnboardingController

  # Discovery feed (feed de matching par jeu)
  forward "/discover",     to: MyApp.Controllers.ProfileDiscoveryController

  # Connexions (demandes et connexions établies)
  forward "/connections",  to: MyApp.Controllers.ConnectionController

  # ============================================
  # Route racine
  # ============================================

  get "/test-matching" do
    html = EEx.eval_file(
      "lib/my_app/templates/test-matching.html.eex",
      assigns: [
        current_user: conn.assigns[:current_user]
      ]
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end

  get "/" do
    current_user = conn.assigns[:current_user]
    flash_success = get_session(conn, :flash_success)

    html = EEx.eval_file(
      "lib/my_app/templates/landing.html.eex",
      assigns: [
        current_user: current_user,
        flash_success: flash_success
      ]
    )

    conn
    |> delete_session(:flash_success)
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end



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
  |> put_resp_header("content-security-policy", "default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; img-src 'self' data: https:;")
end
end
