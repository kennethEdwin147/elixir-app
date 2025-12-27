defmodule MyApp.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :votable_type, :string, null: false  # "post" ou "comment"
      add :votable_id, :bigint, null: false
      add :value, :integer, default: 1, null: false

      timestamps()
    end

    # Index pour performance
    create index(:votes, [:user_id])
    create index(:votes, [:votable_type, :votable_id])

    # Constraint: un user ne peut voter qu'une fois par item
    create unique_index(:votes, [:user_id, :votable_type, :votable_id])
  end
end
