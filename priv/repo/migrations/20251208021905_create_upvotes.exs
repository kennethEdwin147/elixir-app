defmodule MyApp.Repo.Migrations.CreateUpvotes do
  use Ecto.Migration

  def change do
    create table(:upvotes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :announcement_id, references(:announcements, on_delete: :delete_all), null: false

      timestamps()
    end

    # Index pour performance
    create index(:upvotes, [:user_id])
    create index(:upvotes, [:announcement_id])

    # Constraint : 1 user peut upvote 1 annonce max 1 fois
    create unique_index(:upvotes, [:user_id, :announcement_id])
  end
end
