defmodule MyApp.Controllers.RegisterController do
  use Plug.Router
  alias MyApp.Services.Validator
  alias MyApp.Services.UserService

  plug :match
  plug :dispatch

  get "/" do
    html = EEx.eval_file("lib/my_app/templates/auth/register.html.eex",
      assigns: %{
        email_value: "",
        error_msg: nil
      }
    )
    send_resp(conn, 200, html)
  end

  post "/" do
    params = conn.params

    # Validation Laravel-style
    case Validator.validate(params, %{
      email: ["required", "string", "email"],
      password: ["required", "string", {:min, 6}, {:same_as, "password_confirm"}]
    }) do
      {:ok, _} ->
        # Vérifier si email existe
        if UserService.user_exists?(params["email"]) do
          render_error(conn, params["email"], "Cet email est déjà utilisé")
        else
          case create_user_with_username(params) do
            {:ok, user} ->
              conn
              |> put_session(:user_id, user.id)
              |> put_session(:user_email, user.email)
              |> put_resp_header("location", "/onboarding")
              |> send_resp(302, "")

            {:error, changeset} ->
              error_msg = extract_error_message(changeset)
              render_error(conn, params["email"], error_msg)
          end
        end

      {:error, errors} ->
        error_msg = format_errors(errors)
        render_error(conn, params["email"], error_msg)
    end
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  defp create_user_with_username(params) do
    username = params["email"] |> String.split("@") |> List.first()

    user_attrs = %{
      "email" => params["email"],
      "username" => username,
      "password" => params["password"]
    }

    UserService.create_user(user_attrs)
  end

  defp extract_error_message(changeset) do
    case changeset.errors do
      [{field, {msg, _}} | _] -> "#{field}: #{msg}"
      _ -> "Erreur de validation"
    end
  end

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {_field, msg} -> msg end)
    |> Enum.join(", ")
  end

  defp render_error(conn, email_value, error_msg) do
    html = EEx.eval_file("lib/my_app/templates/auth/register.html.eex",
      assigns: %{
        email_value: email_value || "",
        error_msg: error_msg
      }
    )
    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(400, html)
  end
end
