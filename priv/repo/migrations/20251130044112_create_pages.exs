defmodule MyApp.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :slug, :string, null: false
      add :title, :string, null: false
      add :bio, :text
      add :avatar_url, :string
      add :is_primary, :boolean, default: false
      add :theme, :map  # JSON en MySQL (thème/couleurs personnalisés)

      timestamps()
    end

    # Index pour recherche rapide par user_id
    create index(:pages, [:user_id])

    # Index pour recherche rapide par slug
    create index(:pages, [:slug])

    # Contrainte unique : un user ne peut pas avoir 2 pages avec le même slug
    create unique_index(:pages, [:user_id, :slug], name: :unique_user_slug)
  end
end
