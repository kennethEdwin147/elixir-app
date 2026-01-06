# ValoLFG - Algorithme de Matching & Raisons

## Objectif
Montrer à chaque user 5-10 **meilleurs matchs quotidiens** avec des raisons claires expliquant pourquoi ces profils sont suggérés.

---

## Critères de Matching (Scoring)

### Hard Criteria (Poids fort - Obligatoire pour match)

**1. Rank Range (Poids: 3 points)**
- Même rank exact: +3 points
- ±1 tier (ex: Or 2 vs Or 1): +2 points  
- ±2 tiers (ex: Or 2 vs Argent 3): +1 point
- >2 tiers de différence: 0 points (skip)

**Raison affichée:**
- Même rank: "Même rank (Platine 1)"
- Proche: "Rank proche (Or 2 - Or 1)"
- Écart acceptable: "Rank compatible pour progresser ensemble"

**2. Région (Poids: 3 points)**
- Même région exacte: +3 points
- Régions adjacentes compatibles (EU West + EU East): +1 point
- Régions incompatibles (EU + NA): 0 points (skip)

**Raison affichée:**
- "Même région (EU West)"
- "Régions compatibles (EU West / EU East)"

---

### Medium Criteria (Poids moyen - Important mais pas bloquant)

**3. Horaires Compatibles (Poids: 2 points)**
- Au moins 1 jour en commun: +2 points
- 2+ jours en commun: +3 points
- Aucun overlap: 0 points

**Raison affichée:**
- "Horaires compatibles (Mar, Jeu soir)"
- "Disponibles en même temps (3 jours en commun)"

**4. Playstyle (Poids: 2 points)**
- Même playstyle exact: +2 points
- Playstyle "mix" compatible avec tout: +1 point
- Playstyles opposés (tryhard vs chill): 0 points

**Raison affichée:**
- "Même playstyle (Tryhard)"
- "Playstyle flexible (Mix)"

**5. Voice Requirement (Poids: 1 point)**
- Tous deux requièrent mic: +1 point
- Tous deux optionnel: +1 point
- Mismatch (un requis, un optionnel): 0 points

**Raison affichée:**
- "Micro requis pour tous les deux"
- "Communication vocale privilégiée"

---

### Soft Criteria (Poids faible - Bonus)

**6. Vibe Tags en commun (Poids: 1 point par tag)**
- Chaque tag en commun: +1 point
- Max 3 points pour tags

**Raison affichée:**
- "Tags en commun: Tryhard, Mic ON"
- "Même vibe: Lurker, One-trick"

**7. Complémentarité Agents (Poids: 2 points)**
- Rôles complémentaires (Duelist + Sentinel): +2 points
- Rôles identiques (Duelist + Duelist): +0 points

**Raison affichée:**
- "Complémentarité agents (Jett + Cypher)"
- "Synergie rôles (Entry + Support)"

**8. Age Range (Poids: 1 point)**
- Même tranche d'âge: +1 point
- Tranches adjacentes: +0.5 point

**Raison affichée:**
- "Même tranche d'âge (25-30)"

**9. Also Plays (Poids: 1 point par jeu)**
- Jeux en commun (ex: tous deux jouent à LoL): +1 point par jeu
- Max 2 points

**Raison affichée:**
- "Joue aussi à League of Legends"
- "Intérêts gaming communs: LoL, Minecraft"

---

## Calcul du Score Total

**Score minimum pour être suggéré: 5 points**
**Score parfait: 15+ points**

### Catégories de Match

| Score | Qualité | Badge |
|-------|---------|-------|
| 12+   | Excellent | ⭐ Match parfait |
| 8-11  | Très bon | ✓ Excellent match |
| 5-7   | Bon | Bon match |
| <5    | Faible | Non suggéré |

---

## Exemples de Scoring

### Exemple 1: Match Parfait (Score: 13)
**User A:** Or 2, EU West, Tryhard, Main Jett, Dispo Mar/Jeu 19h-23h
**User B:** Or 1, EU West, Tryhard, Main Cypher, Dispo Mar/Ven 20h-00h

**Calcul:**
- Rank proche: +2
- Même région: +3
- Horaires overlap (Mar): +2
- Même playstyle: +2
- Mic tous deux: +1
- Complémentarité (Jett+Cypher): +2
- Tags communs (Tryhard, Mic ON): +2
**Total: 14 points** ⭐

**Raisons affichées:**
```
Pourquoi Sarah?
→ Même région (EU West)
→ Rank proche (Or 2 - Or 1)
→ Horaires compatibles (Mardi soir)
→ Même playstyle (Tryhard)
→ Complémentarité agents (Jett + Cypher)
→ Tags en commun: Tryhard, Mic ON

⭐ Match parfait
```

---

### Exemple 2: Bon Match (Score: 7)
**User A:** Platine 2, EU West, Mix, Main Viper
**User B:** Platine 3, EU East, Chill, Main Omen

**Calcul:**
- Rank proche: +2
- Régions adjacentes: +1
- Playstyle différent mais Mix compatible: +1
- Rôles similaires (Contrôleur): +0
- Mic optionnel tous deux: +1
- Tags communs (Flex): +1
- Also plays LoL tous deux: +1
**Total: 7 points** ✓

**Raisons affichées:**
```
Pourquoi Alex?
→ Rank proche (Platine 2 - Platine 3)
→ Régions compatibles (EU West / EU East)
→ Playstyle flexible (Mix)
→ Joue aussi à League of Legends
```

---

### Exemple 3: Match Rejeté (Score: 3)
**User A:** Or 2, EU West, Tryhard
**User B:** Diamant 1, NA, Chill

**Calcul:**
- Rank gap trop grand (>3 tiers): +0 (skip)
- Régions incompatibles: +0 (skip)
- Playstyle opposé: +0
- Horaires probablement incompatibles (timezone): +0
**Total: 3 points** ❌ Non suggéré

---

## Algorithme de Sélection Quotidienne

### Étapes

1. **Filtrer les candidats éligibles**
   - Profils actifs du même jeu
   - Exclure current_user
   - Exclure profils déjà "passés" aujourd'hui
   - Exclure connexions existantes
   - Exclure demandes pending/declined

2. **Calculer score pour chaque candidat**
   - Appliquer tous les critères
   - Stocker score + raisons

3. **Trier par score DESC**

4. **Prendre top 5-10**
   - Si <5 résultats avec score ≥5: élargir critères
   - Randomiser légèrement l'ordre des scores égaux (variété)

5. **Stocker en cache pour la journée**
   - Key: `daily_matches:#{user_id}:#{date}`
   - Expiration: fin de journée (minuit)

---

## Implémentation Backend

### Contexte Matching
```elixir
defmodule ValoLFG.Matching do
  alias ValoLFG.{Repo, Profiles, Connections}
  alias ValoLFG.Profiles.Profile
  import Ecto.Query

  @min_score 5
  @daily_limit 10

  def daily_matches(user, game_id) do
    # Check cache first
    cache_key = "daily_matches:#{user.id}:#{Date.utc_today()}"
    
    case get_cached_matches(cache_key) do
      nil ->
        matches = compute_daily_matches(user, game_id)
        cache_matches(cache_key, matches)
        matches
      
      cached ->
        cached
    end
  end

  defp compute_daily_matches(user, game_id) do
    current_profile = Profiles.get_for_user_and_game(user.id, game_id)
    
    # Get eligible candidates
    candidates = get_eligible_candidates(user.id, game_id)
    
    # Score each candidate
    scored = Enum.map(candidates, fn candidate ->
      %{score: score, reasons: reasons} = calculate_match_score(current_profile, candidate)
      %{
        profile: candidate,
        score: score,
        reasons: reasons
      }
    end)
    
    # Filter by min score, sort, take top N
    scored
    |> Enum.filter(fn m -> m.score >= @min_score end)
    |> Enum.sort_by(fn m -> {m.score, :rand.uniform()} end, :desc)
    |> Enum.take(@daily_limit)
  end

  defp get_eligible_candidates(user_id, game_id) do
    # Get existing connections and requests
    excluded_ids = get_excluded_user_ids(user_id, game_id)
    
    from(p in Profile,
      where: p.game_id == ^game_id and
             p.user_id != ^user_id and
             p.user_id not in ^excluded_ids and
             p.active == true,
      preload: [:user, :availabilities, :game_specific_data]
    )
    |> Repo.all()
  end

  defp get_excluded_user_ids(user_id, game_id) do
    # Users already connected
    connected = Connections.get_connected_user_ids(user_id, game_id)
    
    # Users with pending/declined requests
    requested = Connections.get_requested_user_ids(user_id, game_id)
    
    connected ++ requested
  end

  def calculate_match_score(profile_a, profile_b) do
    score = 0
    reasons = []

    # 1. Rank
    {rank_score, rank_reason} = score_rank(profile_a.rank, profile_b.rank)
    score = score + rank_score
    reasons = if rank_score > 0, do: reasons ++ [rank_reason], else: reasons

    # 2. Region
    {region_score, region_reason} = score_region(profile_a.region, profile_b.region)
    score = score + region_score
    reasons = if region_score > 0, do: reasons ++ [region_reason], else: reasons

    # 3. Schedule
    {schedule_score, schedule_reason} = score_schedule(profile_a, profile_b)
    score = score + schedule_score
    reasons = if schedule_score > 0, do: reasons ++ [schedule_reason], else: reasons

    # 4. Playstyle
    {style_score, style_reason} = score_playstyle(profile_a.playstyle, profile_b.playstyle)
    score = score + style_score
    reasons = if style_score > 0, do: reasons ++ [style_reason], else: reasons

    # 5. Voice
    {voice_score, voice_reason} = score_voice(profile_a.voice_required, profile_b.voice_required)
    score = score + voice_score
    reasons = if voice_score > 0, do: reasons ++ [voice_reason], else: reasons

    # 6. Vibe tags
    {tags_score, tags_reason} = score_vibe_tags(profile_a.vibe_tags, profile_b.vibe_tags)
    score = score + tags_score
    reasons = if tags_score > 0, do: reasons ++ [tags_reason], else: reasons

    # 7. Agent complementarity
    {agent_score, agent_reason} = score_agents(profile_a, profile_b)
    score = score + agent_score
    reasons = if agent_score > 0, do: reasons ++ [agent_reason], else: reasons

    %{score: score, reasons: reasons}
  end

  # Scoring functions
  defp score_rank(rank_a, rank_b) do
    distance = rank_distance(rank_a, rank_b)
    
    cond do
      rank_a == rank_b -> {3, "Même rank (#{rank_a})"}
      distance == 1 -> {2, "Rank proche (#{rank_a} - #{rank_b})"}
      distance == 2 -> {1, "Rank compatible pour progresser ensemble"}
      true -> {0, nil}
    end
  end

  defp score_region(region_a, region_b) do
    cond do
      region_a == region_b -> {3, "Même région (#{region_a})"}
      adjacent_regions?(region_a, region_b) -> {1, "Régions compatibles (#{region_a} / #{region_b})"}
      true -> {0, nil}
    end
  end

  defp score_schedule(profile_a, profile_b) do
    overlap_days = count_schedule_overlap(profile_a.availabilities, profile_b.availabilities)
    
    cond do
      overlap_days >= 2 -> {3, "Disponibles en même temps (#{overlap_days} jours en commun)"}
      overlap_days == 1 -> {2, "Horaires compatibles"}
      true -> {0, nil}
    end
  end

  defp score_playstyle(style_a, style_b) do
    cond do
      style_a == style_b -> {2, "Même playstyle (#{style_a})"}
      style_a == "mix" or style_b == "mix" -> {1, "Playstyle flexible"}
      true -> {0, nil}
    end
  end

  defp score_voice(voice_a, voice_b) do
    if voice_a == voice_b do
      reason = if voice_a, do: "Micro requis pour tous les deux", else: "Communication vocale optionnelle"
      {1, reason}
    else
      {0, nil}
    end
  end

  defp score_vibe_tags(tags_a, tags_b) do
    common = MapSet.intersection(MapSet.new(tags_a), MapSet.new(tags_b)) |> MapSet.to_list()
    count = length(common)
    
    if count > 0 do
      {min(count, 3), "Tags en commun: #{Enum.join(Enum.take(common, 2), ", ")}"}
    else
      {0, nil}
    end
  end

  defp score_agents(profile_a, profile_b) do
    agent_a = get_main_agent(profile_a)
    agent_b = get_main_agent(profile_b)
    
    if agent_a && agent_b && agents_complementary?(agent_a, agent_b) do
      {2, "Complémentarité agents (#{agent_a} + #{agent_b})"}
    else
      {0, nil}
    end
  end

  # Helper functions
  defp rank_distance(rank_a, rank_b) do
    # Implementation: calculate tier distance
    # Ex: "Or 2" vs "Or 1" = 1
    # Ex: "Or 2" vs "Platine 1" = 3
    0 # Placeholder
  end

  defp adjacent_regions?("EU West", "EU East"), do: true
  defp adjacent_regions?("EU East", "EU West"), do: true
  defp adjacent_regions?(_, _), do: false

  defp count_schedule_overlap(avail_a, avail_b) do
    days_a = Enum.map(avail_a, & &1.day_of_week) |> MapSet.new()
    days_b = Enum.map(avail_b, & &1.day_of_week) |> MapSet.new()
    
    MapSet.intersection(days_a, days_b) |> MapSet.size()
  end

  defp get_main_agent(profile) do
    Enum.find_value(profile.game_specific_data, fn data ->
      if data.key == "main_agent", do: data.value
    end)
  end

  defp agents_complementary?(agent_a, agent_b) do
    # Logic: check if agents have different roles
    # Ex: Jett (Duelist) + Cypher (Sentinel) = true
    # Ex: Jett (Duelist) + Reyna (Duelist) = false
    true # Placeholder
  end

  # Cache functions
  defp get_cached_matches(key), do: nil # Use Cachex or similar
  defp cache_matches(key, matches), do: :ok # Store until midnight
end
```

---

## Affichage dans le Controller
```elixir
defmodule ValoLFGWeb.ProfileController do
  use ValoLFGWeb, :controller
  alias ValoLFG.{Games, Matching}

  def game_index(conn, %{"game" => game_slug}) do
    user = conn.assigns.current_user
    game = Games.get_by_slug!(game_slug)
    
    # Get daily matches with scores and reasons
    matches = Matching.daily_matches(user, game.id)
    
    # Get first match for display
    current_match = List.first(matches)
    
    render(conn, "daily_feed.html",
      game: game,
      matches: matches,
      current_match: current_match,
      current_index: 0,
      total_matches: length(matches)
    )
  end
end
```

---

## Notes importantes

### Refresh des matchs
- **Nouveau batch quotidien:** Minuit (00:00 UTC)
- **Pas de refresh en cours de journée** (encourage à revenir demain)
- Exception: Si user a vu tous les matchs du jour → peut refresh manuellement

### Exclusions
- Profils déjà connectés (connection active)
- Demandes pending (en attente de réponse)
- Demandes declined dans les dernières 48h
- Profils "passés" aujourd'hui

### Edge cases
- Si <5 matchs avec score ≥5: abaisser threshold à 4
- Si toujours <5: montrer message "Pas assez de profils compatibles, reviens demain"
- Nouveaux users: relaxer critères région/rank pour avoir du monde

### A/B Testing potentiel
- Tester différents poids (rank vs horaires)
- Tester nombre de matchs quotidiens (5 vs 10)
- Tester avec/sans raisons affichées

---

## Évolutions futures

**V2 - Machine Learning:**
- Apprendre des connexions acceptées/refusées
- Ajuster poids selon feedback user
- Prédire compatibilité à long terme

**V3 - Facteurs sociaux:**
- Profils populaires (beaucoup de demandes) = bonus
- Nouveaux users = boost temporaire
- Taux de réponse aux demandes

**V4 - Timing:**
- Montrer profils "en ligne maintenant" en premier
- Push notification "X est maintenant en ligne"