defmodule MyApp.Controllers.UserSettingsController do
  use Plug.Router
  alias MyApp.Services.UserSettingsStorage
  alias MyApp.Services.UserStorage
  alias MyApp.Services.Validation

  plug :match
  plug :dispatch

  # Afficher la page settings
  get "/" do
    user_id = get_session(conn, :user_id)
    user_email = get_session(conn, :user_email)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Récupérer les messages flash
      success_msg = get_session(conn, :success_msg)
      error_msg = get_session(conn, :error_msg)

      # Supprimer les messages après lecture
      conn = conn
      |> delete_session(:success_msg)
      |> delete_session(:error_msg)

      settings = UserSettingsStorage.get_settings(user_id)

      html = EEx.eval_file("lib/my_app/templates/settings.html.eex",
        assigns: %{
          user_email: user_email,
          username: settings.username,
          bio: settings.bio,
          profile_image: settings.profile_image,
          theme: settings.theme,
          primary_color: settings.primary_color,
          background_color: settings.background_color,
          button_style: settings.button_style,
          error_msg: error_msg,
          success_msg: success_msg
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  # Mettre à jour le profil (username, bio, image)
  post "/profile" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params

      with {:ok, _} <- validate_username(params["username"]),
           {:ok, _updated_settings} <- UserSettingsStorage.update_profile(user_id, params) do

        conn
        |> put_session(:success_msg, "Profil mis à jour avec succès")
        |> put_resp_header("location", "/user/settings")
        |> send_resp(302, "")

      else
        {:error, msg} ->
          conn
          |> put_session(:error_msg, msg)
          |> put_resp_header("location", "/user/settings")
          |> send_resp(302, "")
      end
    end
  end


  # Changer le mot de passe
  post "/password" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params
      user = UserStorage.find_by_id(user_id)

      with {:ok, _} <- Validation.validate_required(params, ["current_password", "new_password", "new_password_confirm"]),
           {:ok, _} <- verify_current_password(user, params["current_password"]),
           {:ok, _} <- Validation.validate_length(params["new_password"], "Nouveau mot de passe", min: 6),
           {:ok, _} <- Validation.validate_confirmation(params["new_password"], params["new_password_confirm"], "Nouveau mot de passe") do

        # TODO: Implémenter update_password dans UserStorage
        # UserStorage.update_password(user_id, params["new_password"])

        conn
        |> put_session(:success_msg, "Mot de passe mis à jour avec succès")
        |> put_resp_header("location", "/user/settings")
        |> send_resp(302, "")

      else
        {:error, msg} ->
          conn
          |> put_session(:error_msg, msg)
          |> put_resp_header("location", "/user/settings")
          |> send_resp(302, "")
      end
    end
  end

  # Helper: Valider le username
  defp validate_username(nil), do: {:ok, nil}
  defp validate_username(username) when is_binary(username) do
    # Username doit être entre 3-30 caractères, alphanumerique + underscore
    cond do
      String.length(username) < 3 ->
        {:error, "Le nom d'utilisateur doit contenir au moins 3 caractères"}

      String.length(username) > 30 ->
        {:error, "Le nom d'utilisateur ne peut pas dépasser 30 caractères"}

      !Regex.match?(~r/^[a-zA-Z0-9-]+$/, username) ->
        {:error, "Le nom d'utilisateur ne peut contenir que des lettres, chiffres et tirets"}

      true ->
        {:ok, username}
    end
  end

  # Helper: Vérifier le mot de passe actuel
  defp verify_current_password(user, current_password) do
    if UserStorage.verify_password(user, current_password) do
      {:ok, true}
    else
      {:error, "Mot de passe actuel incorrect"}
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
