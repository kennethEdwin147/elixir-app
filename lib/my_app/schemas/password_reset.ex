defmodule MyApp.Schemas.PasswordReset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "password_resets" do
    field :token, :string
    field :expires_at, :utc_datetime

    # Relation vers l'utilisateur
    belongs_to :user, MyApp.Schemas.User

    timestamps(type: :utc_datetime)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:token, :expires_at, :user_id])
    |> validate_required([:token, :expires_at, :user_id])
    # On assure qu'il n'y a qu'un reset à la fois par user
    |> unique_constraint(:user_id)
  end
end
