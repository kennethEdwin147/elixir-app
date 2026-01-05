defmodule MyApp.Schemas.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connections" do
    field :play_count, :integer, default: 0
    field :last_played_at, :utc_datetime

    # Relations - NOTE: Pas de belongs_to standard car on utilise user_id_1 et user_id_2
    field :user_id_1, :binary_id
    field :user_id_2, :binary_id

    belongs_to :game, MyApp.Schemas.Game

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour créer une nouvelle connexion entre deux users.
  IMPORTANT: user_id_1 doit toujours être < user_id_2 pour éviter les doublons.
  """
  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:user_id_1, :user_id_2, :game_id, :play_count, :last_played_at])
    |> validate_required([:user_id_1, :user_id_2, :game_id])
    |> validate_user_order()
    |> foreign_key_constraint(:game_id)
    |> unique_constraint([:user_id_1, :user_id_2, :game_id],
        name: :connections_user_id_1_user_id_2_game_id_index)
  end

  @doc """
  Crée une connexion en s'assurant que user_id_1 < user_id_2.
  """
  def new(user_id_a, user_id_b, game_id) do
    {user_id_1, user_id_2} = order_user_ids(user_id_a, user_id_b)

    %__MODULE__{}
    |> changeset(%{
      user_id_1: user_id_1,
      user_id_2: user_id_2,
      game_id: game_id
    })
  end

  @doc """
  Incrémente le play_count et met à jour last_played_at.
  """
  def increment_play_count(connection) do
    connection
    |> change()
    |> put_change(:play_count, connection.play_count + 1)
    |> put_change(:last_played_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Valide que user_id_1 < user_id_2.
  """
  defp validate_user_order(changeset) do
    user_id_1 = get_field(changeset, :user_id_1)
    user_id_2 = get_field(changeset, :user_id_2)

    if user_id_1 && user_id_2 && user_id_1 >= user_id_2 do
      add_error(changeset, :user_id_1, "must be less than user_id_2")
    else
      changeset
    end
  end

  @doc """
  Retourne les deux user_ids dans l'ordre croissant.
  """
  defp order_user_ids(user_id_a, user_id_b) do
    if user_id_a < user_id_b do
      {user_id_a, user_id_b}
    else
      {user_id_b, user_id_a}
    end
  end
end
