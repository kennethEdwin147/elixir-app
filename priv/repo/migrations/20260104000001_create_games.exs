defmodule MyApp.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string, null: false
      add :name, :string, null: false
      add :active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    # Index unique sur slug pour recherche rapide
    create unique_index(:games, [:slug])
  end
end
