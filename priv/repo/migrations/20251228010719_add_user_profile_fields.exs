defmodule MyApp.Repo.Migrations.AddUserProfileFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :display_name, :string
      add :onboarding_completed, :boolean, default: false
    end

    # Modifie username pour permettre NULL
    alter table(:users) do
      modify :username, :string, null: true
    end

    # Drop unique constraint sur username (SANS if_exists pour MySQL)
    drop unique_index(:users, [:username])  # ← RETIRE if_exists

    # Recréer comme index normal (pas unique)
    create index(:users, [:username])
  end
end
