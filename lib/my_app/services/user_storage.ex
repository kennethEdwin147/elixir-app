defmodule MyApp.Services.UserStorage do
  @moduledoc """
  Gère les utilisateurs sur le filesystem.

  Structure:
      priv/static/users/
      └── users.json
  """

  @users_dir "priv/static/users"
  @users_file Path.join(@users_dir, "users.json")

  # Initialise le fichier users si n'existe pas
  defp init do
    File.mkdir_p!(@users_dir)

    unless File.exists?(@users_file) do
      File.write!(@users_file, Jason.encode!([]))
    end
  end

  @doc """
  Crée un nouvel utilisateur.
  Retourne {:ok, user} ou {:error, reason}
  """
  def create_user(email, password) do
    init()

    if user_exists?(email) do
      {:error, "Cet email est déjà utilisé"}
    else
      user = %{
        id: :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false),
        email: email,
        password_hash: hash_password(password),
        created_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }

      users = load_all_users()
      updated_users = [user | users]

      File.write!(@users_file, Jason.encode!(updated_users))

      {:ok, user}
    end
  end

  @doc """
  Trouve un user par email.
  """
  def find_by_email(email) do
    load_all_users()
    |> Enum.find(&(&1["email"] == email))
    |> case do
      nil -> nil
      user -> Map.new(user, fn {k, v} -> {String.to_atom(k), v} end)
    end
  end

  @doc """
  Trouve un user par ID.
  """
  def find_by_id(user_id) do
    load_all_users()
    |> Enum.find(&(&1["id"] == user_id))
    |> case do
      nil -> nil
      user -> Map.new(user, fn {k, v} -> {String.to_atom(k), v} end)
    end
  end

  @doc """
  Vérifie si email existe.
  """
  def user_exists?(email) do
    find_by_email(email) != nil
  end

  @doc """
  Vérifie le password.
  """
  def verify_password(user, password) do
    user.password_hash == hash_password(password)
  end

  # Charge tous les users
  defp load_all_users do
    init()

    case File.read(@users_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, users} -> users
          {:error, _} -> []
        end
      {:error, _} -> []
    end
  end

  # Hash password (simple pour MVP)
  defp hash_password(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end
end
