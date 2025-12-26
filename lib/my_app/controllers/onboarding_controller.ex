defmodule MyApp.Controllers.OnboardingController do
  use Plug.Router
  alias MyApp.Repo
  alias MyApp.Schemas.User

  plug Plug.Session,
    store: :cookie,
    key: "onboarding_session",
    signing_salt: "some_signing_salt_here"

  plug :match
  plug :dispatch

  get "/" do
    conn
    |> put_resp_header("location", "/onboarding/step1")
    |> send_resp(302, "")
  end

  # ----------------------------------------------------------------
  # ÉTAPE 1: Username
  # ----------------------------------------------------------------

  get "/step1" do
    user_id = get_session(conn, :user_id)
    user_email = get_session(conn, :user_email)

    if is_nil(user_id) do
      conn |> put_resp_header("location", "/register") |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}
      suggested_username = (user_email || "") |> String.split("@") |> List.first()

      html = EEx.eval_file("lib/my_app/templates/onboarding/step1_info.html.eex",
        assigns: %{data: data, suggested_username: suggested_username, error_msg: nil}
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  post "/step1" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn |> put_resp_header("location", "/register") |> send_resp(302, "")
    else
      # Trim direct du paramètre
      username = String.trim(conn.params["username"] || "")
      data = get_session(conn, :onboarding_data) || %{}
      new_data = Map.put(data, :username, username)

      conn
      |> put_session(:onboarding_data, new_data)
      |> put_resp_header("location", "/onboarding/step2")
      |> send_resp(302, "")
    end
  end

  # ----------------------------------------------------------------
  # ÉTAPE 2: Finalisation
  # ----------------------------------------------------------------

  get "/step2" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn |> put_resp_header("location", "/register") |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}
      html = EEx.eval_file("lib/my_app/templates/onboarding/step2_info.html.eex",
        assigns: %{data: data, error_msg: nil}
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  post "/step2" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn |> put_resp_header("location", "/auth/register") |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}
      username = data[:username]

      user = Repo.get(User, user_id)

      case user do
        nil ->
          conn
          |> delete_session(:onboarding_data)
          |> put_resp_header("location", "/auth/register")
          |> send_resp(302, "")

        user ->
          changeset = User.changeset(user, %{"username" => username})

          case Repo.update(changeset) do
            {:ok, _updated_user} ->
              conn
              |> delete_session(:onboarding_data)
              |> put_resp_header("location", "/dashboard")
              |> send_resp(302, "")

            {:error, err_changeset} -> # Renommé pour éviter le warning de variable
              error_msg = extract_error_message(err_changeset)
              html = EEx.eval_file("lib/my_app/templates/onboarding/step2_info.html.eex",
                assigns: %{data: data, error_msg: error_msg}
              )

              conn
              |> put_resp_content_type("text/html", "utf-8")
              |> send_resp(400, html)
          end
      end
    end
  end

  defp extract_error_message(changeset) do
    case changeset.errors do
      [{field, {msg, _}} | _] -> "#{field} #{msg}"
      _ -> "Erreur de mise à jour"
    end
  end
end
