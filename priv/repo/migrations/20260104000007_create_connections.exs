defmodule MyApp.Repo.Migrations.CreateConnections do
  use Ecto.Migration

  def change do
    create table(:connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id_1, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id_2, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :restrict), null: false
      add :play_count, :integer, default: 0
      add :last_played_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Note: Validation user_id_1 < user_id_2 faite dans le schema Ecto
    # MySQL ne supporte pas les contraintes CHECK avec MyXQL

    # Une seule connexion par game entre deux users
    create unique_index(:connections, [:user_id_1, :user_id_2, :game_id])

    # Index pour rechercher les connexions d'un user
    create index(:connections, [:user_id_1, :game_id])
    create index(:connections, [:user_id_2, :game_id])
  end
end
