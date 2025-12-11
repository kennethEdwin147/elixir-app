defmodule MyApp.Repo.Migrations.CreateAnnouncements do
  use Ecto.Migration

  def change do
    create table(:announcements) do
      add :game, :string, null: false
      add :rank, :string
      add :vibe, :string
      add :description, :text, null: false
      add :tags, :text  # MySQL : on stocke en JSON texte
      add :active, :boolean, default: true
      add :expires_at, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # NOUVELLES COLONNES ⬇️
      add :upvotes_count, :integer, default: 0
      add :interested_count, :integer, default: 0

      timestamps()
    end

    create index(:announcements, [:user_id])
    create index(:announcements, [:game])
    create index(:announcements, [:active])
    create index(:announcements, [:expires_at])

    # NOUVEAUX INDEX ⬇️
    create index(:announcements, [:upvotes_count])
    create index(:announcements, [:interested_count])
  end
end
