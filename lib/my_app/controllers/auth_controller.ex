defmodule MyApp.Controllers.AuthController do
  use Plug.Router
  alias MyApp.Services.Validator
  alias MyApp.Contexts.User

  plug :match
  plug :dispatch

  # ============================================================================
  # Login Routes
  # ============================================================================

  # GET  /auth/login     → Affiche le formulaire de connexion
  # POST /auth/login     → Vérifie les identifiants et crée la session
  # GET  /auth/logout    → Détruit la session et redirige vers /login
  # POST /auth/logout    → Détruit la session (plus sécurisé)

  get "login/" do
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

  post "login/" do
    params = conn.params

    case Validator.validate(params, %{
      "email" => ["required", "string", "email"],
      "password" => ["required", "string"]
    }) do
      {:ok, _} ->
        # 1. On cherche l'utilisateur
        user = User.find_by_email(params["email"])

        # 2. On délègue la vérification au service (qui utilisera Bcrypt)
        if User.verify_password(user, params["password"]) do
          conn
          |> configure_session(renew: true) # <--- CRITIQUE : Génère un nouvel ID de session après login
          |> put_session(:user_id, user.id)
          |> put_session(:user_email, user.email)
          |> put_resp_header("location", "/g/valorant")
          |> send_resp(302, "")
        else
          # 3. Message générique pour ne pas révéler si c'est l'email ou le mdp qui est faux
          render_error(conn, "login", params["email"], "Email ou mot de passe incorrect")
        end

      {:error, errors} ->
        render_error(conn, "login", params["email"], format_errors(errors))
    end
  end

  # ============================================================================
  # LOGOUT
  # ============================================================================

  post "/logout" do
    conn
    |> configure_session(drop: true)
    |> put_resp_header("location", "/auth/login")  # ← Corrigé
    |> send_resp(302, "")
  end


  # ============================================================================
  # Register Routes
  # ============================================================================

  # GET  /auth/register  → Affiche le formulaire d'inscription
  # POST /auth/register  → Crée le compte, suggère username, et redirige vers /onboarding

  get "/register" do
    html = EEx.eval_file("lib/my_app/templates/auth/register.html.eex",
      assigns: %{
        email_value: "",
        error_msg: nil
      }
    )

    conn
    |> put_resp_content_type("text/html", "utf-8") # Bonne pratique de préciser le type
    |> send_resp(200, html)
  end

 post "/register" do
  # 1. Nettoyage des données
  params = Map.new(conn.params, fn
    {k, v} when is_binary(v) -> {k, String.trim(v)}
    {k, v} -> {k, v}
  end)

  # 2. Validation
  case Validator.validate(params, %{
    "email" => ["required", "string", "email"],
    "password" => ["required", "string", {:min, 6}, {:same_as, "password_confirm"}]
  }) do
    {:ok, _} ->
      email = String.downcase(params["email"]) # Sécurité : email en minuscules

      if User.user_exists?(email) do
        render_error(conn, "register", email, "Cet email est déjà utilisé")
      else
        case create_user(params) do  # ← Changé (avant: create_user_with_username)
          {:ok, user} ->
            conn
            |> put_session(:user_id, user.id)
            |> put_session(:user_email, user.email)
            |> put_resp_header("location", "/onboarding")  # ← CHANGE ICI
            |> send_resp(302, "")

          {:error, changeset} ->
            error_msg = extract_error_message(changeset)
            render_error(conn, "register", email, error_msg)
        end
      end

    {:error, errors} ->
      error_msg = format_errors(errors)
      render_error(conn, "register", params["email"], error_msg)
  end
end

  # APRÈS
  defp create_user(params) do  # ← Renomme aussi
    user_attrs = %{
      "email" => params["email"],
      # PAS de username, il le choisira dans onboarding
      "password" => params["password"]
    }

    User.create_user(user_attrs)
  end


  defp extract_error_message(changeset) do
    case changeset.errors do
      [{field, {msg, _}} | _] -> "#{field}: #{msg}"
      _ -> "Erreur de validation"
    end
  end

  # ============================================================================
  # Password Routes
  # ============================================================================


  # Demande d'envoi du lien de réinitialisation
  get "/forgot-password" do
    html = EEx.eval_file("lib/my_app/templates/auth/forgot_password.html.eex",
      assigns: %{error_msg: nil, success_msg: nil}
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end

  post "/forgot-password" do
    email = String.trim(conn.params["email"] || "")

    # Sécurité : On affiche le même message même si l'email n'existe pas
    if user = User.find_by_email(email) do
      token = User.generate_reset_token(user)
      # Ici : MyApp.Mailer.send_reset_link(user, token)
    end

    html = EEx.eval_file("lib/my_app/templates/auth/forgot_password.html.eex",
      assigns: %{
        error_msg: nil,
        success_msg: "Si un compte existe pour cet email, un lien de réinitialisation a été envoyé."
      }
    )
    send_resp(conn, 200, html)
  end

  # Formulaire de saisie du nouveau mot de passe
  get "/reset-password" do
    token = conn.params["token"]

    if User.is_token_valid?(token) do
      html = EEx.eval_file("lib/my_app/templates/auth/reset_password.html.eex",
        assigns: %{error_msg: nil, token: token}
      )
      send_resp(conn, 200, html)
    else
      # Si le token est mort, on redirige vers login avec une erreur
      render_error(conn, "login", "", "Le lien est invalide ou a expiré.")
    end
  end

 post "/reset-password" do
    token = conn.params["token"]
    params = conn.params

    # 1. Validation rigoureuse (comme pour l'inscription)
    case Validator.validate(params, %{
      "password" => ["required", "string", {:min, 6}, {:same_as, "password_confirm"}]
    }) do
      {:ok, _} ->
        # 2. On tente la mise à jour si la validation passe
        case User.reset_password_with_token(token, params["password"]) do
          :ok ->
            conn
            |> put_resp_header("location", "/auth/login?success=password_updated")
            |> send_resp(302, "")

          {:error, _msg} ->
            html = EEx.eval_file("lib/my_app/templates/auth/reset_password.html.eex",
              assigns: %{
                error_msg: "Le lien est invalide ou a expiré.",
                token: token
              }
            )
            send_resp(conn, 400, html)
        end

      {:error, errors} ->
        # 3. Erreur de validation (mots de passe différents ou trop courts)
        html = EEx.eval_file("lib/my_app/templates/auth/reset_password.html.eex",
          assigns: %{
            error_msg: format_errors(errors),
            token: token
          }
        )
        send_resp(conn, 400, html)
    end
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {_field, msg} -> msg end)
    |> Enum.join(", ")
  end

  defp render_error(conn, view_name, email_value, error_msg) do
    template_path = "lib/my_app/templates/auth/#{view_name}.html.eex"

    html = EEx.eval_file(template_path,
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
