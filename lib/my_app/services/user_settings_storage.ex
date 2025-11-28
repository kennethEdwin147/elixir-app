defmodule MyApp.Services.UserSettingsStorage do
  @moduledoc """
  Gère les paramètres/profil des utilisateurs sur le filesystem.

  Structure:
      priv/static/users/settings/
      └── {user_id}.json
  """

  @settings_dir "priv/static/users/settings"

  defp settings_file(user_id), do: Path.join(@settings_dir, "#{user_id}.json")

  # Initialise le répertoire settings
  defp init do
    File.mkdir_p!(@settings_dir)
  end

  @doc """
  Récupère les settings d'un utilisateur.
  Retourne un map ou nil si pas de settings.
  """
  def get_settings(user_id) do
    init()
    file = settings_file(user_id)

    if File.exists?(file) do
      case File.read(file) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, settings} -> atomize_keys(settings)
            {:error, _} -> default_settings()
          end
        {:error, _} -> default_settings()
      end
    else
      default_settings()
    end
  end

  @doc """
  Récupère les settings par username (pour afficher la page publique).
  """
  def get_settings_by_username(username) do
    init()

    case File.ls(@settings_dir) do
      {:ok, files} ->
        Enum.find_value(files, fn file ->
          user_id = Path.basename(file, ".json")
          settings = get_settings(user_id)

          if settings.username == username do
            Map.put(settings, :user_id, user_id)
          else
            nil
          end
        end)
      {:error, _} -> nil
    end
  end

  @doc """
  Met à jour le profil d'un utilisateur (username, bio, image).
  Retourne {:ok, settings} ou {:error, reason}
  """
  def update_profile(user_id, params) do
    settings = get_settings(user_id)

    # Check if username is changing AND if it is already taken
    username_taken? =
      params["username"] &&
      params["username"] != settings.username &&
      username_exists?(params["username"])

    if username_taken? do
      # This is now the last line executed in this branch, so it gets returned
      {:error, "Ce nom d'utilisateur est déjà pris"}
    else
      # If not taken, we proceed with the update
      updated_settings = Map.merge(settings, %{
        username: params["username"] || settings.username,
        bio: params["bio"] || settings.bio,
        profile_image: params["profile_image"] || settings.profile_image,
        updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
      })

      save_settings(user_id, updated_settings)
      {:ok, updated_settings}
    end
  end

  @doc """
  Met à jour l'apparence (thème, couleurs).
  """
  def update_appearance(user_id, params) do
    settings = get_settings(user_id)

    updated_settings = Map.merge(settings, %{
      theme: params["theme"] || settings.theme,
      primary_color: params["primary_color"] || settings.primary_color,
      background_color: params["background_color"] || settings.background_color,
      button_style: params["button_style"] || settings.button_style,
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    })

    save_settings(user_id, updated_settings)
    {:ok, updated_settings}
  end

  @doc """
  Vérifie si un username existe déjà.
  """
  def username_exists?(username) do
    get_settings_by_username(username) != nil
  end

  @doc """
  Crée les settings par défaut pour un nouvel utilisateur.
  """
  def create_default_settings(user_id) do
    settings = default_settings()
    |> Map.put(:created_at, DateTime.utc_now() |> DateTime.to_iso8601())

    save_settings(user_id, settings)
    {:ok, settings}
  end

  # Helpers privés

  defp default_settings do
    %{
      username: nil,
      bio: "",
      profile_image: nil,
      theme: "default",
      primary_color: "#3B82F6",
      background_color: "#FFFFFF",
      button_style: "rounded",
      created_at: nil,
      updated_at: nil
    }
  end

  defp save_settings(user_id, settings) do
    init()
    file = settings_file(user_id)
    settings_json = stringify_keys(settings)
    File.write!(file, Jason.encode!(settings_json))
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
