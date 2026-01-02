defmodule MyApp.Plugs.RequireOnboarding do

  # =============================================================================
  # RequireOnboarding Plug
  # =============================================================================
  # Force l'utilisateur connecté à compléter son onboarding avant d'accéder
  # aux routes protégées de l'application.
  #
  # Appliqué après LoadUser dans router.ex.
  #
  # Comportement:
  #   - Si pas connecté (current_user = nil): laisse passer (app publique)
  #   - Si connecté ET onboarding_completed = false: redirect /onboarding
  #   - Si connecté ET onboarding_completed = true: laisse passer
  #
  # Whitelist (skip le check onboarding):
  #   - Routes /onboarding
  #   - Routes /auth/*
  #   - Routes /g/* (voir feed en mode public)
  #
  # Routes protégées (nécessitent onboarding complété):
  #   - POST /g/:slug/submit (créer post)
  #   - GET /dashboard
  #   - etc.
  # =============================================================================

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = conn.assigns[:current_user]

    # Si pas connecté → laisse passer (app publique)
    if is_nil(current_user) do
      conn
    else
      # User connecté → check onboarding pour certaines routes
      skip_paths = ["/onboarding", "/auth/"]

      should_skip? = Enum.any?(skip_paths, fn path ->
        String.starts_with?(conn.request_path, path)
      end)

      if should_skip? do
        conn
      else
        # Routes protégées (créer post, dashboard, etc.)
        if current_user.onboarding_completed do
          conn
        else
          conn
          |> put_resp_header("location", "/onboarding")
          |> send_resp(302, "")
          |> halt()
        end
      end
    end
  end
end
