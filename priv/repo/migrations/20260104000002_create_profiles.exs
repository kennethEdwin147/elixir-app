defmodule MyApp.Repo.Migrations.CreateProfiles do
  use Ecto.Migration

  def change do
    create table(:profiles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :restrict), null: false
      add :bio, :text
      add :age_range, :string
      add :rank, :string
      add :region, :string
      add :playstyle, :string
      add :voice_required, :boolean, default: false
      add :vibe_tags, :text  # JSON array stored as text
      add :active, :boolean, default: true
      add :last_boosted_at, :utc_datetime
      add :last_active_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Un user peut avoir UN seul profile par jeu
    create unique_index(:profiles, [:user_id, :game_id])

    # Index pour feed principal (tri par boost puis activité)
    create index(:profiles, [:game_id, :active, :last_boosted_at, :last_active_at])

    # Index pour filtres
    create index(:profiles, [:game_id, :rank, :region])

    # Index pour user_id (recherche profiles d'un user)
    create index(:profiles, [:user_id])
  end
end
