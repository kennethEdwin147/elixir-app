defmodule MyApp.Plugs.RequireAuth do
  # =============================================================================
# RequireAuth Plug (OPTIONNEL - Non utilisé dans le MVP)
# =============================================================================
# Redirige automatiquement vers /auth/login si current_user est nil.
#
# Utilisation si besoin (pour protéger un controller entier):
#   defmodule MyApp.Controllers.ProtectedController do
#     plug :match
#     plug MyApp.Plugs.RequireAuth  # ← Toutes les routes nécessitent login
#     plug :dispatch
#   end
#
# MVP actuel: On fait la protection manuellement dans chaque route avec:
#   unless current_user do ... redirect login ... end
# =============================================================================

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
      |> halt()
    end
  end
end
