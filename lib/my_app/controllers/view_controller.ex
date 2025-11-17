defmodule MyApp.Controllers.ViewController do
  @moduledoc """
  Affiche les Wrapped générés.
  """

  use Plug.Router

  plug :match
  plug :dispatch

  # Affiche un Wrapped généré avec ses slides animées.

  get "/:id" do
    wrap_id = conn.path_params["id"]

    html = EEx.eval_file("lib/my_app/templates/view/show.html.eex",
      assigns: %{
        wrap_id: wrap_id
      }
    )

    send_resp(conn, 200, html)
  end
end
