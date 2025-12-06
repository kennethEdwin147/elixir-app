defmodule MyApp.Services.UserService do
  @moduledoc """
  Service pour gérer les utilisateurs avec Ecto.
  Remplace UserStorage (JSON).
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.User

  @doc """
  Crée un nouvel utilisateur.
  Retourne {:ok, user} ou {:error, changeset}
  """
  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Trouve un user par email.
  """
  def find_by_email(email) do
    User
    |> where([u], u.email == ^email)
    |> Repo.one()
  end

  @doc """
  Trouve un user par ID.
  """
  def find_by_id(user_id) do
    Repo.get(User, user_id)
  end

  @doc """
  Vérifie si un email existe déjà.
  """
  def user_exists?(email) do
    User
    |> where([u], u.email == ^email)
    |> Repo.exists?()
  end

  @doc """
  Vérifie le password.
  """
  def verify_password(user, password) do
    user.password_hash == hash_password(password)
  end

  @doc """
  Liste tous les users (admin).
  """
  def list_all do
    Repo.all(User)
  end

  # Hash password (même méthode que UserStorage pour compatibilité)
  defp hash_password(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end
end
