defmodule MyApp.Matching do
  @moduledoc """
  Module de matching pour découvrir des profils compatibles.

  ## Version MVP
  Retourne les 5 premiers profils actifs du jeu avec raisons génériques.

  ## TODO - Version complète
  Implémenter l'algorithme complet avec:
  - Scoring basé sur rank, région, horaires, playstyle
  - Calcul des raisons de matching détaillées
  - Tri par score décroissant
  - Cache quotidien des matchs
  - Exclusion des profils déjà vus/passés
  """

  alias MyApp.{Repo, Schemas.Profile}
  import Ecto.Query

  @doc """
  Retourne les meilleurs matchs quotidiens pour un user sur un jeu.

  Pour MVP: Retourne simplement les 5 premiers profils actifs (sauf current_user).

  ## Exemples
      iex> daily_matches(user, game_id)
      [
        %{
          profile: %Profile{...},
          score: 5,
          reasons: ["Même région (EU West)", "Rank compatible", "Profil actif"]
        }
      ]
  """
  def daily_matches(user, game_id, limit \\ 5) do
    # Récupérer le profil de l'utilisateur pour ce jeu
    user_profile = get_user_profile(user.id, game_id)

    # Récupérer profils actifs du jeu (sauf current_user)
    profiles =
      from(p in Profile,
        where:
          p.game_id == ^game_id and
            p.user_id != ^user.id and
            p.active == true,
        preload: [:user, :game, :game_specific_data, :availabilities],
        limit: ^limit,
        order_by: [desc: p.last_active_at]
      )
      |> Repo.all()
      |> Enum.map(&Profile.decode_vibe_tags/1)

    # Pour MVP: retourner avec des raisons génériques
    Enum.map(profiles, fn profile ->
      %{
        profile: profile,
        score: 5,
        # Score fictif pour MVP
        reasons: generate_mock_reasons(profile, user_profile)
      }
    end)
  end

  # Récupérer le profil de l'utilisateur pour ce jeu
  defp get_user_profile(user_id, game_id) do
    from(p in Profile,
      where: p.user_id == ^user_id and p.game_id == ^game_id,
      preload: [:game_specific_data]
    )
    |> Repo.one()
  end

  # Générer des raisons génériques pour MVP
  defp generate_mock_reasons(profile, user_profile) do
    base_reasons = []

    # Même région
    region_reasons =
      if user_profile && profile.region == user_profile.region do
        ["Même région (#{profile.region})"]
      else
        ["Région: #{profile.region}"]
      end

    # Rank
    rank_reasons = ["Rank: #{profile.rank}"]

    # Playstyle
    playstyle_reasons =
      if profile.playstyle do
        ["Playstyle: #{profile.playstyle}"]
      else
        []
      end

    # Profil actif
    active_reasons = ["Profil actif"]

    base_reasons ++ region_reasons ++ rank_reasons ++ playstyle_reasons ++ active_reasons
  end

  # ============================================================================
  # TODO - Algorithme complet
  # ============================================================================

  # TODO: Implémenter calculate_match_score/2 avec l'algo complet
  # defp calculate_match_score(profile_a, profile_b) do
  #   score = 0
  #   reasons = []
  #
  #   # 1. Rank proximity (poids 3)
  #   {rank_score, rank_reason} = score_rank(profile_a.rank, profile_b.rank)
  #   score = score + rank_score
  #   reasons = if rank_score > 0, do: reasons ++ [rank_reason], else: reasons
  #
  #   # 2. Région (poids 3)
  #   {region_score, region_reason} = score_region(profile_a.region, profile_b.region)
  #   score = score + region_score
  #   reasons = if region_score > 0, do: reasons ++ [region_reason], else: reasons
  #
  #   # 3. Horaires overlap (poids 2)
  #   {schedule_score, schedule_reason} = score_schedule(profile_a, profile_b)
  #   score = score + schedule_score
  #   reasons = if schedule_score > 0, do: reasons ++ [schedule_reason], else: reasons
  #
  #   # 4. Playstyle compatibility (poids 2)
  #   {style_score, style_reason} = score_playstyle(profile_a.playstyle, profile_b.playstyle)
  #   score = score + style_score
  #   reasons = if style_score > 0, do: reasons ++ [style_reason], else: reasons
  #
  #   # 5. Voice requirement (poids 1)
  #   {voice_score, voice_reason} = score_voice(profile_a.voice_required, profile_b.voice_required)
  #   score = score + voice_score
  #   reasons = if voice_score > 0, do: reasons ++ [voice_reason], else: reasons
  #
  #   # 6. Vibe tags overlap (poids 1 par tag)
  #   {tags_score, tags_reason} = score_vibe_tags(profile_a.vibe_tags, profile_b.vibe_tags)
  #   score = score + tags_score
  #   reasons = if tags_score > 0, do: reasons ++ [tags_reason], else: reasons
  #
  #   %{score: score, reasons: reasons}
  # end
end
