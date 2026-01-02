defmodule MyApp.Controllers.HomeController do
  use Plug.Router

  alias MyApp.Services.PostService
  alias MyApp.Repo

  plug :match
  plug :dispatch

  get "/" do
  recent_posts = PostService.list_recent(10)
  current_user = conn.assigns[:current_user]
  game = %{slug: "valorant", name: "Valorant"}

  html = EEx.eval_file(
    "lib/my_app/templates/landing.html.eex",
    assigns: [
      posts: recent_posts,
      current_user: current_user,
      game: game,
      slug: "valorant"
    ]
  )

  conn
  |> put_resp_content_type("text/html", "utf-8")  # ← EXACTEMENT!
  |> send_resp(200, html)
end
end
