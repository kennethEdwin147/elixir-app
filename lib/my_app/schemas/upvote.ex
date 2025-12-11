defmodule MyApp.Schemas.Upvote do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.Schemas.{User, Announcement}

  schema "upvotes" do
    belongs_to :user, User
    belongs_to :announcement, Announcement

    timestamps()
  end

  def changeset(upvote, attrs) do
    upvote
    |> cast(attrs, [:user_id, :announcement_id])
    |> validate_required([:user_id, :announcement_id])
    |> unique_constraint([:user_id, :announcement_id], name: :upvotes_user_id_announcement_id_index)
  end
end
