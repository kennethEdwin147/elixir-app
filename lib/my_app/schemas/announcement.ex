defmodule MyApp.Schemas.Announcement do
  use Ecto.Schema
  import Ecto.Changeset
  alias MyApp.Schemas.User

  schema "announcements" do
    field :game, :string
    field :rank, :string
    field :vibe, :string
    field :description, :string
    field :tags, :string  # Stocké comme JSON string
    field :active, :boolean, default: true
    field :expires_at, :utc_datetime

    # NOUVEAUX CHAMPS ⬇️
    field :upvotes_count, :integer, default: 0
    field :interested_count, :integer, default: 0

    belongs_to :user, User

    timestamps()
  end

  def changeset(announcement, attrs) do
    announcement
    |> cast(attrs, [:game, :rank, :vibe, :description, :tags, :user_id])
    |> validate_required([:game, :description, :user_id])
    |> validate_length(:description, max: 500, min: 10)
    |> encode_tags()
    |> put_expiration()
    |> foreign_key_constraint(:user_id)
  end

  # Encode les tags (array) en JSON avant de sauvegarder
  defp encode_tags(changeset) do
    case get_change(changeset, :tags) do
      nil -> changeset
      tags when is_list(tags) ->
        put_change(changeset, :tags, Jason.encode!(tags))
      _ -> changeset
    end
  end

  # Ajoute automatiquement la date d'expiration (24h après création).
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

  def complete_changeset(announcement) do
    announcement
    |> change(%{active: false})
  end

  # Helper pour décoder les tags après lecture
  def decode_tags(announcement) do
    case announcement.tags do
      nil -> %{announcement | tags: []}
      "" -> %{announcement | tags: []}
      json_string when is_binary(json_string) ->
        tags = Jason.decode!(json_string)
        %{announcement | tags: tags}
      list when is_list(list) -> announcement
    end
  end
end
