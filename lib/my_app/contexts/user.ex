defmodule MyApp.Contexts.User do
  @moduledoc """
  Service pour gérer les utilisateurs avec Ecto.
  Remplace UserStorage (JSON).
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.User
  alias MyApp.Schemas.PasswordReset


  @doc """
  Crée un nouvel utilisateur.
  Retourne {:ok, user} ou {:error, changeset}
  """
 def create_user(attrs) do
    # On s'assure que l'email est en minuscules avant de créer le changeset
    attrs = update_in(attrs, ["email"], fn
      nil -> nil
      email -> String.downcase(String.trim(email))
    end)

    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Trouve un user par email.
  """
  def find_by_email(email) when is_binary(email) do
    email_downcased = String.downcase(String.trim(email))

    User
    |> where([u], u.email == ^email_downcased)
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
  def user_exists?(email) when is_binary(email) do
    email_downcased = String.downcase(String.trim(email))

    User
    |> where([u], u.email == ^email_downcased)
    |> Repo.exists?()
  end

  @doc """
  Vérifie le password.
  """
  def verify_password(user, password) do
    case user do
      nil ->
        # Simule un calcul de hash même si l'user n'existe pas
        # pour que le temps de réponse soit le même
        Bcrypt.no_user_verify()
        false

      user ->
        # Compare le mot de passe en clair avec le hash stocké
        Bcrypt.verify_pass(password, user.password_hash)
    end
  end

  @doc """
  Liste tous les users (admin).
  """
  def list_all do
    Repo.all(User)
  end




  # ============================================================================
  # PASSWORD RESET
  # ============================================================================


  # Génère et enregistre le token dans la table dédiée
  def generate_reset_token(%User{} = user) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    expires_at = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)

    # On supprime l'ancien token s'il existe (pour éviter le conflit unique_index)
    Repo.delete_all(from p in PasswordReset, where: p.user_id == ^user.id)

    %PasswordReset{}
    |> PasswordReset.changeset(%{
      token: token,
      expires_at: expires_at,
      user_id: user.id
    })
    |> Repo.insert!()

    token
  end

  # Vérifie si le token existe et n'est pas expiré
  def is_token_valid?(token) do
    query = from p in PasswordReset,
            where: p.token == ^token,
            select: p.expires_at

    case Repo.one(query) do
      nil -> false
      expires_at ->
        DateTime.compare(expires_at, DateTime.utc_now()) == :gt
    end
  end

  # Reset le password et nettoie la table
  def reset_password_with_token(token, new_password) do
    reset_data = Repo.get_by(PasswordReset, token: token) |> Repo.preload(:user)

    cond do
      is_nil(reset_data) ->
        {:error, :invalid_token}

      DateTime.compare(reset_data.expires_at, DateTime.utc_now()) == :lt ->
        Repo.delete(reset_data) # On nettoie le token expiré
        {:error, :invalid_token}

      true ->
        Repo.transaction(fn ->
          # 1. Met à jour l'utilisateur
          user_changeset = User.registration_changeset(reset_data.user, %{"password" => new_password})
          Repo.update!(user_changeset)

          # 2. Supprime le token utilisé
          Repo.delete!(reset_data)

          :ok
        end)
        |> case do
          {:ok, :ok} -> :ok
          _ -> {:error, "Erreur lors de la mise à jour."}
        end
    end
  end


  @doc """
  Supprime tous les tokens de réinitialisation expirés de la table password_resets.
  Appelée automatiquement par le CleanupWorker.
  """
  def delete_expired_tokens do
    now = DateTime.utc_now()

    # On crée la requête pour cibler les tokens dont la date d'expiration est passée
    query = from p in PasswordReset, where: p.expires_at < ^now

    # On exécute la suppression massive
    Repo.delete_all(query)
  end



    @doc """
  Complete l'onboarding d'un user (username + display_name).
  """
  def complete_onboarding(user_id, attrs) do
    user = find_by_id(user_id)

    user
    |> User.onboarding_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Vérifie si un user a complété son onboarding.
  """
  def onboarding_completed?(user) do
    user.onboarding_completed == true
  end

end
