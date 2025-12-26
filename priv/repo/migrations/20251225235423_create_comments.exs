defmodule MyApp.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text, null: false
      add :score, :integer, default: 0
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :post_id, references(:posts, on_delete: :delete_all), null: false
      add :parent_id, references(:comments, on_delete: :delete_all)  # ← NOUVEAU

      timestamps()
    end

    create index(:comments, [:user_id])
    create index(:comments, [:post_id])
    create index(:comments, [:parent_id])  # ← NOUVEAU
    create index(:comments, [:score])
  end
end
