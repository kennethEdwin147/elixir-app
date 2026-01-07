defmodule MyApp.Contexts.Profile do
  @moduledoc """
  Service pour gérer les profiles de jeu des utilisateurs.
  Un user peut avoir UN profile par jeu.

  ## CRUD
  - create_profile(attrs)                    # Créer profile
  - create_with_game_data(user, game_id, attrs)  # Créer profile + game_specific_data (transaction)
  - update_profile(id, attrs)                # Modifier
  - activate_profile(id)                     # Activer (visible)
  - deactivate_profile(id)                   # Désactiver (invisible)

  ## Récupération
  - get_profile(id)                          # Par ID
  - get_profile_with_details(id)             # Avec game_specific_data
  - get_user_profile_for_game(user_id, game_id)  # Profile spécifique
  - list_user_profiles(user_id)              # Tous les profiles d'un user
  - has_profile_for_game?(user_id, game_id)  # Vérifie existence

  ## Feed principal
  - get_feed(game_id, opts)                  # Feed avec filtres
    # Options: limit, filters (rank, region, playstyle, voice_required)
    # Tri: boosted first, puis last_active_at

  ## Activité & Boost
  - update_activity(id)                      # Met à jour last_active_at
  - boost_profile(id)                        # Boost premium (top du feed)

  ## Game Specific Data
  - set_game_data(profile_id, key, value)    # Ex: "main_agent" => "Jett"
  - get_game_data(profile_id, key)           # Récupère une clé
  - get_all_game_data(profile_id)            # Toutes les données en map
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.{Profile, GameSpecificData}

  # ============================================================================
  # CRÉATION & MODIFICATION
  # ============================================================================

  @doc """
  Crée un nouveau profile pour un user sur un jeu.

  ## Exemples
      iex> create_profile(%{
        user_id: "uuid-123",
        game_id: "uuid-456",
        bio: "Chill player",
        rank: "Gold 2",
        region: "EU West"
      })
      {:ok, %Profile{}}
  """
  def create_profile(attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Crée un profile avec game_specific_data en une transaction.
  Utilisé pour l'onboarding.

  ## Exemples
      iex> create_with_game_data(user, game_id, %{
        "bio" => "Jett main",
        "rank" => "Platine 2",
        "main_agent" => "Jett",
        "secondary_agent" => "Reyna"
      })
      {:ok, %Profile{}}
  """
  def create_with_game_data(user, game_id, attrs) do
    Repo.transaction(fn ->
      # Extraire game_specific_data du attrs
      main_agent = attrs["main_agent"]
      secondary_agent = attrs["secondary_agent"]

      # Créer le profile
      profile =
        %Profile{}
        |> Profile.changeset(%{
          user_id: user.id,
          game_id: game_id,
          bio: attrs["bio"],
          age_range: attrs["age_range"],
          rank: attrs["rank"],
          region: attrs["region"],
          playstyle: attrs["playstyle"],
          voice_required: attrs["voice_required"] == "true" || attrs["voice_required"] == true,
          vibe_tags: attrs["vibe_tags"] || [],
          active: true,
          last_active_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.insert!()

      # Créer game_specific_data pour main_agent
      if main_agent && main_agent != "" do
        %GameSpecificData{}
        |> GameSpecificData.changeset(%{
          profile_id: profile.id,
          key: "main_agent",
          value: main_agent
        })
        |> Repo.insert!()
      end

      # Créer game_specific_data pour secondary_agent si présent
      if secondary_agent && secondary_agent != "" && secondary_agent != "Aucun" do
        %GameSpecificData{}
        |> GameSpecificData.changeset(%{
          profile_id: profile.id,
          key: "secondary_agent",
          value: secondary_agent
        })
        |> Repo.insert!()
      end

      profile
    end)
  end

  @doc """
  Met à jour un profile existant.
  """
  def update_profile(profile_id, attrs) do
    case get_profile(profile_id) do
      nil ->
        {:error, :not_found}

      profile ->
        profile
        |> Profile.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Active un profile (visible dans le feed).
  """
  def activate_profile(profile_id) do
    update_profile(profile_id, %{active: true})
  end

  @doc """
  Désactive un profile (invisible dans le feed).
  """
  def deactivate_profile(profile_id) do
    update_profile(profile_id, %{active: false})
  end

  @doc """
  Met à jour le timestamp last_active_at d'un profile.
  Utilisé pour garder le profile actif dans le feed.
  """
  def update_activity(profile_id) do
    case get_profile(profile_id) do
      nil ->
        {:error, :not_found}

      profile ->
        profile
        |> Ecto.Changeset.change(%{
          last_active_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update()
    end
  end

  @doc """
  Boost un profile (feature premium).
  Met à jour last_boosted_at pour apparaître en haut du feed.
  """
  def boost_profile(profile_id) do
    case get_profile(profile_id) do
      nil ->
        {:error, :not_found}

      profile ->
        profile
        |> Ecto.Changeset.change(%{
          last_boosted_at: DateTime.utc_now() |> DateTime.truncate(:second),
          last_active_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update()
    end
  end

  # ============================================================================
  # RÉCUPÉRATION
  # ============================================================================

  @doc """
  Récupère un profile par ID.
  Preload user et game.
  """
  def get_profile(profile_id) do
    Profile
    |> where([p], p.id == ^profile_id)
    |> preload([:user, :game])
    |> Repo.one()
  end

  @doc """
  Récupère un profile avec toutes ses données (game_specific_data, availabilities).
  """
  def get_profile_with_details(profile_id) do
    Profile
    |> where([p], p.id == ^profile_id)
    |> preload([:user, :game, :game_specific_data, :availabilities])
    |> Repo.one()
    |> decode_vibe_tags_if_present()
  end

  @doc """
  Récupère le profile d'un user pour un jeu spécifique.
  Retourne nil si non trouvé.
  """
  def get_user_profile_for_game(user_id, game_id) do
    Profile
    |> where([p], p.user_id == ^user_id and p.game_id == ^game_id)
    |> preload([:user, :game])
    |> Repo.one()
    |> decode_vibe_tags_if_present()
  end

  @doc """
  Liste tous les profiles d'un user (tous jeux confondus).
  """
  def list_user_profiles(user_id) do
    Profile
    |> where([p], p.user_id == ^user_id)
    |> preload([:game])
    |> order_by([p], desc: p.last_active_at)
    |> Repo.all()
    |> Enum.map(&decode_vibe_tags_if_present/1)
  end

  @doc """
  Vérifie si un user a déjà un profile pour un jeu.
  """
  def has_profile_for_game?(user_id, game_id) do
    Profile
    |> where([p], p.user_id == ^user_id and p.game_id == ^game_id)
    |> Repo.exists?()
  end

  # ============================================================================
  # FEED PRINCIPAL
  # ============================================================================

  @doc """
  Récupère le feed de profiles pour un jeu.
  Tri par: boosted profiles en premier, puis par activité récente.

  Options:
    - limit: nombre de résultats (défaut: 50)
    - filters: map de filtres optionnels
      - rank: filtrer par rank
      - region: filtrer par region
      - playstyle: filtrer par playstyle
      - voice_required: true/false
  """
  def get_feed(game_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    filters = Keyword.get(opts, :filters, %{})

    query =
      Profile
      |> where([p], p.game_id == ^game_id and p.active == true)
      |> preload([:user, :game])
      |> apply_filters(filters)
      |> order_by([p], [
        # Boosted profiles first
        fragment("CASE WHEN ? IS NOT NULL THEN 0 ELSE 1 END", p.last_boosted_at),
        desc: p.last_boosted_at,
        desc: p.last_active_at
      ])
      |> limit(^limit)

    query
    |> Repo.all()
    |> Enum.map(&decode_vibe_tags_if_present/1)
  end

  # ============================================================================
  # GAME SPECIFIC DATA
  # ============================================================================

  @doc """
  Ajoute ou met à jour une donnée spécifique au jeu pour un profile.

  ## Exemples
      iex> set_game_data(profile_id, "main_agent", "Jett")
      {:ok, %GameSpecificData{}}
  """
  def set_game_data(profile_id, key, value) do
    case Repo.get_by(GameSpecificData, profile_id: profile_id, key: key) do
      nil ->
        # Créer nouvelle entrée
        %GameSpecificData{}
        |> GameSpecificData.changeset(%{
          profile_id: profile_id,
          key: key,
          value: value
        })
        |> Repo.insert()

      existing ->
        # Mettre à jour
        existing
        |> GameSpecificData.changeset(%{value: value})
        |> Repo.update()
    end
  end

  @doc """
  Récupère une donnée spécifique pour un profile.
  """
  def get_game_data(profile_id, key) do
    case Repo.get_by(GameSpecificData, profile_id: profile_id, key: key) do
      nil -> nil
      data -> data.value
    end
  end

  @doc """
  Récupère toutes les données spécifiques d'un profile sous forme de map.

  ## Exemples
      iex> get_all_game_data(profile_id)
      %{"main_agent" => "Jett", "secondary_agent" => "Reyna"}
  """
  def get_all_game_data(profile_id) do
    GameSpecificData
    |> where([d], d.profile_id == ^profile_id)
    |> Repo.all()
    |> Enum.into(%{}, fn data -> {data.key, data.value} end)
  end

  # ============================================================================
  # HELPERS PRIVÉS
  # ============================================================================

  defp apply_filters(query, filters) do
    query
    |> filter_by_rank(Map.get(filters, :rank))
    |> filter_by_region(Map.get(filters, :region))
    |> filter_by_playstyle(Map.get(filters, :playstyle))
    |> filter_by_voice(Map.get(filters, :voice_required))
  end

  defp filter_by_rank(query, nil), do: query
  defp filter_by_rank(query, rank), do: where(query, [p], p.rank == ^rank)

  defp filter_by_region(query, nil), do: query
  defp filter_by_region(query, region), do: where(query, [p], p.region == ^region)

  defp filter_by_playstyle(query, nil), do: query
  defp filter_by_playstyle(query, playstyle), do: where(query, [p], p.playstyle == ^playstyle)

  defp filter_by_voice(query, nil), do: query
  defp filter_by_voice(query, voice_required), do: where(query, [p], p.voice_required == ^voice_required)

  defp decode_vibe_tags_if_present(nil), do: nil
  defp decode_vibe_tags_if_present(profile), do: Profile.decode_vibe_tags(profile)
end
