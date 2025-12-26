# lib/my_app/schemas/comment.ex
defmodule MyApp.Schemas.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.Schemas.{User, Post, Comment}

  schema "comments" do
    field :body, :string
    field :score, :integer, default: 0

    belongs_to :user, User
    belongs_to :post, Post
    belongs_to :parent, Comment  # ← NOUVEAU: pour threading

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body, :user_id, :post_id, :parent_id])  # ← Ajoute parent_id
    |> validate_required([:body, :user_id, :post_id])
    |> validate_length(:body, min: 1, max: 2000)
  end
end
