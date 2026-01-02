defmodule MyApp.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string
    field :display_name, :string  # ← NOUVEAU
    field :password_hash, :string
    field :password, :string, virtual: true
    field :onboarding_completed, :boolean, default: false  # ← NOUVEAU

    timestamps()
  end

  @doc """
  Utilisé pour l'onboarding - complete le profil après inscription.
  """
  def onboarding_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :display_name])
    |> validate_required([:username, :display_name])
    |> normalize_username()
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]+$/, message: "only letters, numbers, underscore and dash")  # ← Ajoute -
    # PAS de unique_constraint sur username (duplicates OK)
    |> put_change(:onboarding_completed, true)
  end

  @doc """
  Utilisé pour l'onboarding et les mises à jour de profil.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :display_name])
    |> validate_required([:username])
    |> normalize_username()
    # RETIRE unique_constraint sur username
    |> unique_constraint(:email)
  end

  @doc """
  Utilisé uniquement lors de l'inscription (Register).
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> normalize_email()
    |> normalize_username()
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    # RETIRE unique_constraint sur username (duplicates OK)
    |> put_password_hash()
  end

  # --- Fonctions de normalisation privées ---

  defp normalize_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      email -> put_change(changeset, :email, String.downcase(String.trim(email)))
    end
  end

  defp normalize_username(changeset) do
    case get_change(changeset, :username) do
      nil -> changeset
      username -> put_change(changeset, :username, String.trim(username))
    end
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
      _ ->
        changeset
    end
  end
end
