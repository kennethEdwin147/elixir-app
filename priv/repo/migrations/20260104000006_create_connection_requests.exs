defmodule MyApp.Repo.Migrations.CreateConnectionRequests do
  use Ecto.Migration

  def change do
    create table(:connection_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :requester_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :target_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :restrict), null: false
      add :status, :string, default: "pending", null: false
      add :message, :text

      timestamps(type: :utc_datetime)
    end

    # Note: Validation requester_id != target_id faite dans le schema Ecto
    # MySQL ne supporte pas les contraintes CHECK avec MyXQL

    # Une seule demande par game entre deux users
    create unique_index(:connection_requests, [:requester_id, :target_id, :game_id])

    # Index pour mes demandes reçues
    create index(:connection_requests, [:target_id, :status, :game_id])

    # Index pour mes demandes envoyées
    create index(:connection_requests, [:requester_id, :game_id])
  end
end
