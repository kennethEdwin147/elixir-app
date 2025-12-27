defmodule MyApp.Schemas.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "votes" do
    field :votable_type, :string
    field :votable_id, :integer
    field :value, :integer, default: 1

    belongs_to :user, MyApp.Schemas.User

    timestamps()
  end

  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:user_id, :votable_type, :votable_id, :value])
    |> validate_required([:user_id, :votable_type, :votable_id, :value])
    |> validate_inclusion(:votable_type, ["post", "comment"])
    |> validate_inclusion(:value, [1, -1])
    |> unique_constraint([:user_id, :votable_type, :votable_id])
  end
end
