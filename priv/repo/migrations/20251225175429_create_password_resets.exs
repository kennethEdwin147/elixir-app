defmodule MyApp.Repo.Migrations.CreatePasswordResets do
  use Ecto.Migration

  def change do
    create table(:password_resets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :token, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    # Index pour chercher le token rapidement
    create index(:password_resets, [:token])

    # Index pour chercher par user_id
    create unique_index(:password_resets, [:user_id])
  end
end
