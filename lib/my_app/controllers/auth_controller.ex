defmodule MyApp.Controllers.AuthController do
  use Plug.Router
  alias MyApp.Services.Validation


  plug :match
  plug :dispatch

  # Formulaire de login
  get "/login" do
    html = EEx.eval_file("lib/my_app/templates/login.html.eex",
      assigns: %{
        email_value: "",
        error_msg: nil
      }
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end


  # Traitement du login
  post "/login" do
    params = conn.params
    IO.inspect(conn.params, label: "Params reçus")

    with {:ok, _} <- Validation.validate_required(params, ["email", "password"]),
         {:ok, _} <- Validation.validate_email(params["email"]),
         {:ok, _} <- Validation.validate_length(params["password"], "Mot de passe", min: 6) do # <--- CORRECTION DU 'do' MANQUANT
      conn
        |> put_session(:user_email, params["email"])
        |> put_resp_header("location", "/user/dashboard")
        |> send_resp(302, "")

    else
      {:error, msg} ->
          IO.inspect(msg, label: "Erreur login")
        html = EEx.eval_file("lib/my_app/templates/login.html.eex",
          assigns: %{
            email_value: params["email"] || "",
            error_msg: msg
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)
    end
  end


  # Déconnexion
  post "/logout" do
    # Ici tu détruis la session ou invalide le cookie
    conn
    |> configure_session(drop: true)
    |> send_resp(200, "Déconnexion effectuée")
  end

end # <--- Fin du module. Assurez-vous d'avoir bien fermé tous les blocs précédents.
