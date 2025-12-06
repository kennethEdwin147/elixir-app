defmodule MyApp.Controllers.LoginController do
  use Plug.Router
  alias MyApp.Services.Validation
  alias MyApp.Services.UserService  # ⬅️ CHANGÉ

  plug :match
  plug :dispatch

  get "/" do
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

  post "/" do
    params = conn.params

    with {:ok, _} <- Validation.validate_required(params, ["email", "password"]),
         {:ok, _} <- Validation.validate_email(params["email"]),
         user when not is_nil(user) <- UserService.find_by_email(params["email"]),  # ⬅️ CHANGÉ
         true <- UserService.verify_password(user, params["password"]) do  # ⬅️ CHANGÉ

      conn
      |> put_session(:user_id, user.id)
      |> put_session(:user_email, user.email)
      |> put_resp_header("location", "/dashboard")
      |> send_resp(302, "")

    else
      _ ->
        html = EEx.eval_file("lib/my_app/templates/login.html.eex",
          assigns: %{
            email_value: params["email"] || "",
            error_msg: "Email ou mot de passe incorrect"
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)
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
end
