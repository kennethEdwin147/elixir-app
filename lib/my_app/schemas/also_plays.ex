defmodule MyApp.Schemas.AlsoPlays do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "also_plays" do
    # Relations
    belongs_to :user, MyApp.Schemas.User
    belongs_to :game, MyApp.Schemas.Game

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour indiquer qu'un user joue aussi à un autre jeu.
  Utilisé pour les affinités entre gamers.
  """
  def changeset(also_plays, attrs) do
    also_plays
    |> cast(attrs, [:user_id, :game_id])
    |> validate_required([:user_id, :game_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:game_id)
    |> unique_constraint([:user_id, :game_id], name: :also_plays_user_id_game_id_index)
  end
end
