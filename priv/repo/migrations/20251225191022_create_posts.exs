defmodule MyApp.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :type, :string, default: "lfg", null: false
      add :url, :string
      add :game, :string, null: false
      add :rank, :string
      add :region, :string
      add :contact, :string
      add :description, :text, null: false
      add :tags, :text
      add :active, :boolean, default: true
      add :expires_at, :utc_datetime
      add :score, :integer, default: 0
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:game])
    create index(:posts, [:type])
    create index(:posts, [:active])
    create index(:posts, [:expires_at])
    create index(:posts, [:score])
  end
end
