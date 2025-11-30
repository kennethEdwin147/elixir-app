defmodule MyApp.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :page_id, references(:pages, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :url, :string, null: false
      add :icon, :string
      add :position, :integer, default: 0
      add :clicks_count, :integer, default: 0
      add :is_active, :boolean, default: true

      timestamps()
    end

    # Index pour recherche rapide par page_id
    create index(:links, [:page_id])

    # Index pour tri par position (ordre d'affichage)
    create index(:links, [:position])
  end
end
