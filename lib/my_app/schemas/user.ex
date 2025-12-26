defmodule MyApp.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    has_many :announcements, MyApp.Schemas.Announcement
    timestamps()
  end

  @doc """
  Utilisé pour l'onboarding et les mises à jour de profil.
  C'est cette fonction que OnboardingController appelle à la ligne 104.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username]) # On cast les champs modifiables
    |> validate_required([:username])         # On force le username
    |> normalize_username()
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  @doc """
  Utilisé uniquement lors de l'inscription (Register).
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_required([:email, :username, :password])
    |> normalize_email()
    |> normalize_username()
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
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
