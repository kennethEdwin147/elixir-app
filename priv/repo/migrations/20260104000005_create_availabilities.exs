defmodule MyApp.Repo.Migrations.CreateAvailabilities do
  use Ecto.Migration

  def change do
    create table(:availabilities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, references(:profiles, type: :binary_id, on_delete: :delete_all), null: false
      add :day_of_week, :integer, null: false
      add :start_time, :time, null: false
      add :end_time, :time, null: false

      timestamps(type: :utc_datetime)
    end

    # Note: Validation day_of_week (0-6) faite dans le schema Ecto
    # MySQL ne supporte pas les contraintes CHECK avec MyXQL

    # Index pour rechercher les disponibilités d'un profile
    create index(:availabilities, [:profile_id])
  end
end
