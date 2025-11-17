defmodule MyApp.Controllers.UserController do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/dashboard" do
    html = EEx.eval_file("lib/my_app/templates/dashboard.html.eex", assigns: [name: "Kenneth"])
    send_resp(conn, 200, html)
  end
end
