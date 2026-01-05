defmodule MyApp.Repo.Migrations.CreateAlsoPlays do
  use Ecto.Migration

  def change do
    create table(:also_plays, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    # Un user ne peut avoir qu'une seule entrée par jeu
    create unique_index(:also_plays, [:user_id, :game_id])

    # Index pour rechercher tous les jeux d'un user
    create index(:also_plays, [:user_id])
  end
end
