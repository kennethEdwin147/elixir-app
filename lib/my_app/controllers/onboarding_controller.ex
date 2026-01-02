defmodule MyApp.Controllers.OnboardingController do
  use Plug.Router
  alias MyApp.Services.UserService
  alias MyApp.Schemas.User

  plug Plug.Session,
    store: :cookie,
    key: "onboarding_session",
    signing_salt: "some_signing_salt_here"

  plug :match
  plug :dispatch

  # ----------------------------------------------------------------
  # GET /onboarding - Affiche le formulaire
  # ----------------------------------------------------------------
  get "/" do
    current_user = conn.assigns[:current_user]

    if is_nil(current_user) do
      conn
      |> put_resp_header("location", "/auth/register")
      |> send_resp(302, "")
    else
      # Si déjà complété, redirect dashboard
      if current_user.onboarding_completed do
        conn
        |> put_resp_header("location", "/g/valorant")
        |> send_resp(302, "")
      else
        # Suggestion username depuis email
      # Dans GET "/"
      suggested_username = current_user.email
        |> String.split("@")
        |> List.first()
        |> then(fn base -> "#{base}#{:rand.uniform(9000) + 999}" end)  # Ajoute 1000-9999

        html = EEx.eval_file("lib/my_app/templates/onboarding/form.html.eex",
          assigns: %{
            user: current_user,
            current_user: current_user,
            suggested_username: suggested_username,
            error_msg: nil
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(200, html)
      end
    end
  end

  # ----------------------------------------------------------------
  # POST /onboarding - Soumet le formulaire
  # ----------------------------------------------------------------
 post "/" do
  current_user = conn.assigns[:current_user]

  if is_nil(current_user) do
    conn
    |> put_resp_header("location", "/auth/register")
    |> send_resp(302, "")
  else
    attrs = %{
      "username" => String.trim(conn.params["username"] || ""),
      "display_name" => String.trim(conn.params["display_name"] || "")
    }

    case UserService.complete_onboarding(current_user.id, attrs) do
      {:ok, _user} ->
        conn
        |> put_resp_header("location", "/g/valorant")
        |> send_resp(302, "")

      {:error, changeset} ->
        suggested_username = current_user.email |> String.split("@") |> List.first()
        error_msg = extract_error_message(changeset)

        html = EEx.eval_file("lib/my_app/templates/onboarding/form.html.eex",
          assigns: %{
            user: current_user,
            current_user: current_user,
            suggested_username: suggested_username,
            error_msg: error_msg
          }
        )

        conn
        |> put_resp_content_type("text/html", "utf-8")
        |> send_resp(400, html)
    end
  end
end

  # Helper pour extraire message d'erreur
  defp extract_error_message(changeset) do
    case changeset.errors do
      [{field, {msg, _}} | _] -> "#{field}: #{msg}"
      _ -> "Erreur de mise à jour"
    end
  end
end
