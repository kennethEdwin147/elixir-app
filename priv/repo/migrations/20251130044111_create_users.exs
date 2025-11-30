defmodule MyApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false

      timestamps()  # Ajoute inserted_at et updated_at automatiquement
    end

    # Index pour recherche rapide par email
    create unique_index(:users, [:email])

    # Index pour recherche rapide par username (URL publique)
    create unique_index(:users, [:username])
  end
end
