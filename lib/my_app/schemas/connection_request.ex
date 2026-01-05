defmodule MyApp.Schemas.ConnectionRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connection_requests" do
    field :status, :string, default: "pending"
    field :message, :string

    # Relations
    belongs_to :requester, MyApp.Schemas.User
    belongs_to :target, MyApp.Schemas.User
    belongs_to :game, MyApp.Schemas.Game

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour créer une nouvelle demande de connexion.
  """
  def changeset(connection_request, attrs) do
    connection_request
    |> cast(attrs, [:requester_id, :target_id, :game_id, :status, :message])
    |> validate_required([:requester_id, :target_id, :game_id])
    |> validate_inclusion(:status, ["pending", "accepted", "declined"])
    |> validate_length(:message, max: 500)
    |> validate_not_self_request()
    |> foreign_key_constraint(:requester_id)
    |> foreign_key_constraint(:target_id)
    |> foreign_key_constraint(:game_id)
    |> unique_constraint([:requester_id, :target_id, :game_id],
        name: :connection_requests_requester_id_target_id_game_id_index)
  end

  @doc """
  Changeset pour accepter ou refuser une demande.
  """
  def status_changeset(connection_request, status) when status in ["accepted", "declined"] do
    connection_request
    |> change(status: status)
    |> validate_inclusion(:status, ["pending", "accepted", "declined"])
  end

  @doc """
  Valide que requester_id != target_id.
  """
  defp validate_not_self_request(changeset) do
    requester_id = get_field(changeset, :requester_id)
    target_id = get_field(changeset, :target_id)

    if requester_id && target_id && requester_id == target_id do
      add_error(changeset, :target_id, "cannot send request to yourself")
    else
      changeset
    end
  end
end
