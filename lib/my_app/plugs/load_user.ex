defmodule MyApp.Plugs.LoadUser do

# =============================================================================
# LoadUser Plug
# =============================================================================
# Charge automatiquement le current_user depuis la session pour TOUTES les requêtes.
#
# Appliqué globalement dans router.ex (après fetch_session).
#
# Résultat: conn.assigns[:current_user] est disponible partout
#   - Si connecté: %User{}
#   - Si pas connecté: nil
#
# Usage dans les controllers:
#   current_user = conn.assigns[:current_user]
#   if current_user do ... end
# =============================================================================

  import Plug.Conn
  alias MyApp.Repo
  alias MyApp.Schemas.User

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    if user_id do
      user = MyApp.Repo.get(User, user_id)
      assign(conn, :current_user, user)
    else
      assign(conn, :current_user, nil)
    end
  end
end
