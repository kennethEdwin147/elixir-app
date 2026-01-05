defmodule MyApp.Schemas.Profile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "profiles" do
    field :bio, :string
    field :age_range, :string
    field :rank, :string
    field :region, :string
    field :playstyle, :string
    field :voice_required, :boolean, default: false
    field :vibe_tags, :string  # JSON array stored as text
    field :active, :boolean, default: true
    field :last_boosted_at, :utc_datetime
    field :last_active_at, :utc_datetime

    # Relations
    belongs_to :user, MyApp.Schemas.User
    belongs_to :game, MyApp.Schemas.Game
    has_many :game_specific_data, MyApp.Schemas.GameSpecificData
    has_many :availabilities, MyApp.Schemas.Availability

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset pour créer un nouveau profile.
  """
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :user_id,
      :game_id,
      :bio,
      :age_range,
      :rank,
      :region,
      :playstyle,
      :voice_required,
      :vibe_tags,
      :active,
      :last_boosted_at,
      :last_active_at
    ])
    |> validate_required([:user_id, :game_id])
    |> validate_length(:bio, max: 500)
    |> validate_inclusion(:age_range, ["18-24", "25-30", "30+"], allow_nil: true)
    |> encode_vibe_tags()
    |> set_last_active_at()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:game_id)
    |> unique_constraint([:user_id, :game_id], name: :profiles_user_id_game_id_index)
  end

  @doc """
  Encode vibe_tags array to JSON string.
  """
  defp encode_vibe_tags(changeset) do
    case get_change(changeset, :vibe_tags) do
      nil ->
        changeset

      tags when is_list(tags) ->
        put_change(changeset, :vibe_tags, Jason.encode!(tags))

      "" ->
        put_change(changeset, :vibe_tags, Jason.encode!([]))

      tags when is_binary(tags) ->
        # Si c'est déjà une string JSON, on la garde
        changeset

      _ ->
        changeset
    end
  end

  @doc """
  Set last_active_at to now if not provided.
  """
  defp set_last_active_at(changeset) do
    case get_field(changeset, :last_active_at) do
      nil ->
        put_change(changeset, :last_active_at, DateTime.utc_now() |> DateTime.truncate(:second))

      _ ->
        changeset
    end
  end

  @doc """
  Decode vibe_tags JSON string to array.
  """
  def decode_vibe_tags(profile) do
    case profile.vibe_tags do
      nil -> %{profile | vibe_tags: []}
      "" -> %{profile | vibe_tags: []}
      json_string when is_binary(json_string) ->
        tags = Jason.decode!(json_string)
        %{profile | vibe_tags: tags}
      list when is_list(list) -> profile
    end
  end
end
