defmodule MyApp.Controllers.CreateController do
  @moduledoc """
  Gère le flow de création d'un Wrapped.
  """

  use Plug.Router

  plug :match
  plug :dispatch


  # Affiche la page d'accueil pour créer un nouveau Wrapped.
  # Génère un ID unique pour le wrap.

  get "/" do
    wrap_id = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)

    html = EEx.eval_file("lib/my_app/templates/create/new.html.eex",
      assigns: %{
        wrap_id: wrap_id
      }
    )

    send_resp(conn, 200, html)
  end


  # Affiche une slide spécifique du Wrapped.
  # L'utilisateur peut uploader des photos pour cette slide.

  get "/:id/step/:step_num" do
    wrap_id = conn.path_params["id"]
    step_num = String.to_integer(conn.path_params["step_num"])

    html = EEx.eval_file("lib/my_app/templates/create/step.html.eex",
      assigns: %{
        wrap_id: wrap_id,
        step_num: step_num,
        total_steps: 7
      }
    )

    send_resp(conn, 200, html)
  end


  # Sauvegarde les photos d'une slide et redirige vers la suivante.

  post "/:id/step/:step_num" do
    wrap_id = conn.path_params["id"]
    step_num = String.to_integer(conn.path_params["step_num"])

    # Limiter à 7 slides max
    next_path = cond do
      step_num >= 7 -> "/create/#{wrap_id}/review"
      step_num < 1 -> "/create/#{wrap_id}/step/1"
      true -> "/create/#{wrap_id}/step/#{step_num + 1}"
    end

    conn
    |> put_resp_header("location", next_path)
    |> send_resp(302, "")
  end


  # Affiche le preview de toutes les slides avant génération finale.

  get "/:id/review" do
    wrap_id = conn.path_params["id"]

    html = EEx.eval_file("lib/my_app/templates/create/review.html.eex",
      assigns: %{
        wrap_id: wrap_id
      }
    )

    send_resp(conn, 200, html)
  end


  # Lance la génération du Wrapped final et redirige vers la page de résultat.

  post "/:id/generate" do
    wrap_id = conn.path_params["id"]

    conn
    |> put_resp_header("location", "/w/#{wrap_id}")
    |> send_resp(302, "")
  end
end
