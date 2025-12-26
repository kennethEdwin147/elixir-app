defmodule MyApp.Schemas.Post do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.Schemas.User

  schema "posts" do
    field :type, :string, default: "lfg"  # "lfg", "strat", "clip"
    field :url, :string                    # Lien externe (strat/clip seulement)
    field :game, :string
    field :rank, :string
    field :region, :string
    field :contact, :string
    field :description, :string
    field :tags, :string  # JSON string
    field :active, :boolean, default: true
    field :expires_at, :utc_datetime
    field :score, :integer, default: 0

    belongs_to :user, User
    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:type, :url, :game, :rank, :region, :contact, :description, :tags, :user_id])
    |> validate_required([:type, :game, :description, :user_id])
    |> validate_inclusion(:type, ["lfg", "strat", "clip"])
    |> validate_length(:description, max: 500, min: 10)
    |> validate_by_type()
    |> encode_tags()
    |> put_expiration()
    |> foreign_key_constraint(:user_id)
  end

  defp validate_by_type(changeset) do
    case get_field(changeset, :type) do
      "lfg" ->
        changeset
        |> validate_required([:rank, :region, :contact])

      type when type in ["strat", "clip"] ->
        changeset
        |> validate_required([:url])
        |> validate_format(:url, ~r/^https?:\/\/.+/, message: "doit être une URL valide")

      _ ->
        changeset
    end
  end

  defp encode_tags(changeset) do
    case get_change(changeset, :tags) do
      nil -> changeset
      tags when is_list(tags) ->
        put_change(changeset, :tags, Jason.encode!(tags))
      _ -> changeset
    end
  end

  defp put_expiration(changeset) do
    case get_field(changeset, :expires_at) do
      nil ->
        expires_at = DateTime.utc_now()
        |> DateTime.add(24 * 60 * 60, :second)
        |> DateTime.truncate(:second)
        put_change(changeset, :expires_at, expires_at)
      _ ->
        changeset
    end
  end

  def decode_tags(post) do
    case post.tags do
      nil -> %{post | tags: []}
      "" -> %{post | tags: []}
      json_string when is_binary(json_string) ->
        tags = Jason.decode!(json_string)
        %{post | tags: tags}
      list when is_list(list) -> post
    end
  end
end
