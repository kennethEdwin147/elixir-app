defmodule MyApp.Schemas.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "games" do
    field :slug, :string
    field :name, :string
    field :active, :boolean, default: true

    # Relations
    has_many :profiles, MyApp.Schemas.Profile
    has_many :connection_requests, MyApp.Schemas.ConnectionRequest
    has_many :connections, MyApp.Schemas.Connection
    has_many :also_plays, MyApp.Schemas.AlsoPlays

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour créer/modifier un jeu.
  """
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:slug, :name, :active])
    |> validate_required([:slug, :name])
    |> validate_format(:slug, ~r/^[a-z0-9_-]+$/, message: "must be lowercase alphanumeric with dashes/underscores")
    |> unique_constraint(:slug)
  end
end
