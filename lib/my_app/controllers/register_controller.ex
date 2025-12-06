defmodule MyApp.Controllers.RegisterController do
  use Plug.Router
  alias MyApp.Services.Validation
  alias MyApp.Services.UserService  # ⬅️ CHANGÉ

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
         {:ok, _} <- Validation.validate_length(params["password"], "Mot de passe", min: 6),
         {:ok, _} <- Validation.validate_confirmation(params["password"], params["password_confirm"], "Mot de passe"),
         false <- UserService.user_exists?(params["email"]),  # ⬅️ AJOUTÉ (vérif email unique)
         {:ok, user} <- create_user_with_username(params) do  # ⬅️ CHANGÉ

      # User créé, login auto et redirect vers onboarding
      conn
      |> put_session(:user_id, user.id)
      |> put_session(:user_email, user.email)
      |> put_resp_header("location", "/onboarding")
      |> send_resp(302, "")

    else
      {:error, %Ecto.Changeset{} = changeset} ->
        # Erreur Ecto, extraire le message
        error_msg = extract_error_message(changeset)

        html = EEx.eval_file("lib/my_app/templates/register.html.eex",
          assigns: %{
            email_value: params["email"] || "",
            error_msg: error_msg
          }
        )
        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)

      {:error, msg} when is_binary(msg) ->
        html = EEx.eval_file("lib/my_app/templates/register.html.eex",
          assigns: %{
            email_value: params["email"] || "",
            error_msg: msg
          }
        )
        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)

      true ->
        # user_exists? retourne true
        html = EEx.eval_file("lib/my_app/templates/register.html.eex",
          assigns: %{
            email_value: params["email"] || "",
            error_msg: "Cet email est déjà utilisé"
          }
        )
        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)

      _ ->
        html = EEx.eval_file("lib/my_app/templates/register.html.eex",
          assigns: %{
            email_value: params["email"] || "",
            error_msg: "Erreur lors de la création du compte"
          }
        )
        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)
    end
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  # Crée un user avec username généré depuis l'email
  defp create_user_with_username(params) do
    # Génère un username depuis l'email (avant le @)
    username = params["email"] |> String.split("@") |> List.first()

    user_attrs = %{
      "email" => params["email"],
      "username" => username,
      "password" => params["password"]
    }

    UserService.create_user(user_attrs)
  end

  # Extrait un message d'erreur lisible du changeset
  defp extract_error_message(changeset) do
    case changeset.errors do
      [{field, {msg, _}} | _] -> "#{field}: #{msg}"
      _ -> "Erreur de validation"
    end
  end
end
