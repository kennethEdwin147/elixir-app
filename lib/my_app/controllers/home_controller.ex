defmodule MyApp.Controllers.HomeController do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    html = EEx.eval_file("lib/my_app/templates/index.html.eex", assigns: [name: "Kenneth"])
    send_resp(conn, 200, html)
  end
end
