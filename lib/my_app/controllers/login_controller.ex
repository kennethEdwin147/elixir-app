defmodule MyApp.Controllers.LoginController do
  use Plug.Router
  alias MyApp.Services.Validator
  alias MyApp.Services.UserService

  plug :match
  plug :dispatch

  get "/" do
    html = EEx.eval_file("lib/my_app/templates/auth/login.html.eex",
      assigns: %{
        email_value: "",
        error_msg: nil
      }
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end

  post "/" do
    params = conn.params

    # Validation Laravel-style
    case Validator.validate(params, %{
      email: ["required", "string", "email"],
      password: ["required", "string"]
    }) do
      {:ok, _} ->
        # Vérifier credentials
        case UserService.find_by_email(params["email"]) do
          nil ->
            render_error(conn, params["email"], "Email ou mot de passe incorrect")

          user ->
            if UserService.verify_password(user, params["password"]) do
              conn
              |> put_session(:user_id, user.id)
              |> put_session(:user_email, user.email)
              |> put_resp_header("location", "/dashboard")
              |> send_resp(302, "")
            else
              render_error(conn, params["email"], "Email ou mot de passe incorrect")
            end
        end

      {:error, errors} ->
        error_msg = format_errors(errors)
        render_error(conn, params["email"], error_msg)
    end
  end

  post "/logout" do
    conn
    |> configure_session(drop: true)
    |> put_resp_header("location", "/")
    |> send_resp(302, "")
  end

  get "/logout" do
    conn
    |> configure_session(drop: true)
    |> put_resp_header("location", "/login")
    |> send_resp(302, "")
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {_field, msg} -> msg end)
    |> Enum.join(", ")
  end

  defp render_error(conn, email_value, error_msg) do
    html = EEx.eval_file("lib/my_app/templates/login.html.eex",
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
