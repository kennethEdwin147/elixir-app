defmodule MyApp.Schemas.GameSpecificData do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "game_specific_data" do
    field :key, :string
    field :value, :string

    # Relations
    belongs_to :profile, MyApp.Schemas.Profile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour créer/modifier des données spécifiques au jeu.

  Exemples:
  - Valorant: key="main_agent", value="Jett"
  - Apex: key="main_legend", value="Wraith"
  - LoL: key="main_role", value="ADC"
  """
  def changeset(game_specific_data, attrs) do
    game_specific_data
    |> cast(attrs, [:profile_id, :key, :value])
    |> validate_required([:profile_id, :key, :value])
    |> validate_length(:key, max: 100)
    |> validate_length(:value, max: 255)
    |> foreign_key_constraint(:profile_id)
  end
end
