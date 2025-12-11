defmodule MyApp.Repo.Migrations.CreateInterested do
  use Ecto.Migration

  def change do
    create table(:interested) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :announcement_id, references(:announcements, on_delete: :delete_all), null: false

      timestamps()
    end

    # Index pour performance
    create index(:interested, [:user_id])
    create index(:interested, [:announcement_id])

    # Constraint : 1 user peut être interested 1 fois par annonce
    create unique_index(:interested, [:user_id, :announcement_id])
  end
end
