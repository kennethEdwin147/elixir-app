defmodule MyApp.Schemas.Availability do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "availabilities" do
    field :day_of_week, :integer
    field :start_time, :time
    field :end_time, :time

    # Relations
    belongs_to :profile, MyApp.Schemas.Profile

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour créer/modifier une disponibilité.

  day_of_week: 0=Dimanche, 1=Lundi, ..., 6=Samedi
  start_time et end_time: format "HH:MM:SS"
  """
  def changeset(availability, attrs) do
    availability
    |> cast(attrs, [:profile_id, :day_of_week, :start_time, :end_time])
    |> validate_required([:profile_id, :day_of_week, :start_time, :end_time])
    |> validate_inclusion(:day_of_week, 0..6, message: "must be between 0 (Sunday) and 6 (Saturday)")
    |> validate_time_range()
    |> foreign_key_constraint(:profile_id)
  end

  @doc """
  Valide que end_time est après start_time.
  """
  defp validate_time_range(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && Time.compare(end_time, start_time) != :gt do
      add_error(changeset, :end_time, "must be after start_time")
    else
      changeset
    end
  end
end
