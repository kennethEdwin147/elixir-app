defmodule MyApp.Repo.Migrations.CreateGameSpecificData do
  use Ecto.Migration

  def change do
    create table(:game_specific_data, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :profile_id, references(:profiles, type: :binary_id, on_delete: :delete_all), null: false
      add :key, :string, null: false
      add :value, :string, null: false

      timestamps(type: :utc_datetime)
    end

    # Index pour rechercher toutes les données d'un profile
    create index(:game_specific_data, [:profile_id])

    # Index pour rechercher une clé spécifique d'un profile
    create index(:game_specific_data, [:profile_id, :key])
  end
end
