defmodule MyApp.Schemas.Interested do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.Schemas.{User, Announcement}

  schema "interested" do
    belongs_to :user, User
    belongs_to :announcement, Announcement

    timestamps()
  end

  def changeset(interested, attrs) do
    interested
    |> cast(attrs, [:user_id, :announcement_id])
    |> validate_required([:user_id, :announcement_id])
    |> unique_constraint([:user_id, :announcement_id], name: :interested_user_id_announcement_id_index)
  end
end
