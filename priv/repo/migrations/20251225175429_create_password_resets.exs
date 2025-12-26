defmodule MyApp.Repo.Migrations.CreatePasswordResets do
  use Ecto.Migration

  def change do
    create table(:password_resets) do
      # Ajoute une référence à ta table users
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :expires_at, :naive_datetime, null: false

      timestamps() # Crée inserted_at et updated_at automatiquement
    end

    # Optionnel mais recommandé : un index pour chercher le token rapidement
    create index(:password_resets, [:token])
  end
end
