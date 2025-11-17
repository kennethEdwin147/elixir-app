defmodule MyApp.Controllers.RegisterController do
  use Plug.Router
  alias MyApp.Services.Validation

  plug :match
  plug :dispatch

  get "/" do
    html = EEx.eval_file("lib/my_app/templates/register.html.eex",
      assigns: %{
        email_value: "",
        error_msg: nil
      }
    )
    send_resp(conn, 200, html)
  end

  post "/" do
    params = conn.params

    with {:ok, _} <- Validation.validate_required(params, ["email", "password", "password_confirm"]),
         {:ok, _} <- Validation.validate_email(params["email"]),
         {:ok, _} <- Validation.validate_length(params["password"], "Mot de passe", min: 6), # CORRIGÉ : Ajout du nom du champ "Mot de passe"
         {:ok, _} <- Validation.validate_confirmation(params["password"], params["password_confirm"], "Mot de passe") do

      send_resp(conn, 200, "Utilisateur créé: #{params["email"]} ")

    else
      {:error, msg} ->
        html = EEx.eval_file("lib/my_app/templates/register.html.eex",
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

end
