defmodule MyApp.Controllers.OnboardingController do
  use Plug.Router
  alias MyApp.Repo
  alias MyApp.Schemas.User

  # Routes:
  # GET  /onboarding           → redirect to step1
  # GET  /onboarding/step1     → step1 (username)
  # POST /onboarding/step1     → process step1, redirect to step2
  # GET  /onboarding/step2     → step2 (champ additionnel pour plus tard)
  # POST /onboarding/step2     → process step2, finalize & redirect to listing

  plug Plug.Session,
    store: :cookie,
    key: "onboarding_session",
    signing_salt: "some_signing_salt_here"

  plug :match
  plug :dispatch

  # --- Route principale (Redirection vers la première étape) ---
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

    # Si pas connecté, redirect vers register
    unless user_id do
      conn
      |> put_resp_header("location", "/register")
      |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}

      # Suggère un username depuis l'email
      suggested_username = user_email |> String.split("@") |> List.first()

      html = EEx.eval_file("lib/my_app/templates/onboarding/step1_info.html.eex",
        assigns: %{
          data: data,
          suggested_username: suggested_username,
          error_msg: nil
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  post "/step1" do
    user_id = get_session(conn, :user_id)
    params = conn.params

    unless user_id do
      conn
      |> put_resp_header("location", "/register")
      |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}

      # Stockage des données
      new_data = Map.merge(data, %{
        username: params["username"]
      })

      # Passe à l'étape 2
      conn
      |> put_session(:onboarding_data, new_data)
      |> put_resp_header("location", "/onboarding/step2")
      |> send_resp(302, "")
    end
  end

  # ----------------------------------------------------------------
  # ÉTAPE 2: Champ additionnel (pour plus tard) - FINALISATION
  # ----------------------------------------------------------------

  get "/step2" do
    user_id = get_session(conn, :user_id)

    unless user_id do
      conn
      |> put_resp_header("location", "/register")
      |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}

      html = EEx.eval_file("lib/my_app/templates/onboarding/step2_info.html.eex",
        assigns: %{
          data: data,
          error_msg: nil
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  post "/step2" do
    user_id = get_session(conn, :user_id)
    params = conn.params

    unless user_id do
      conn
      |> put_resp_header("location", "/register")
      |> send_resp(302, "")
    else
      data = get_session(conn, :onboarding_data) || %{}

      # Finalisation des données
      final_data = Map.merge(data, %{
        bio: params["bio"]  # Champ additionnel
      })

      # ============================================================================
      # MISE À JOUR DU USER EXISTANT
      # ============================================================================

      user = Repo.get(User, user_id)

      case user do
        nil ->
          # User introuvable
          conn
          |> delete_session(:onboarding_data)
          |> put_resp_header("location", "/register")
          |> send_resp(302, "")

        user ->
          # Mise à jour du username
          changeset = User.changeset(user, %{
            username: final_data.username
          })

          case Repo.update(changeset) do
            {:ok, _updated_user} ->
              # Succès
              conn
              |> delete_session(:onboarding_data)
              |> put_resp_header("location", "/")
              |> send_resp(302, "")

            {:error, changeset} ->
              # Erreur (username déjà pris, etc.)
              error_msg = extract_error_message(changeset)

              html = EEx.eval_file("lib/my_app/templates/onboarding/step2_info.html.eex",
                assigns: %{
                  data: final_data,
                  error_msg: error_msg
                }
              )

              conn
              |> put_resp_content_type("text/html", "utf-8")
              |> send_resp(400, html)
          end
      end
    end
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  defp extract_error_message(changeset) do
    case changeset.errors do
      [{field, {msg, _}} | _] -> "#{field}: #{msg}"
      _ -> "Erreur lors de la mise à jour"
    end
  end
end
