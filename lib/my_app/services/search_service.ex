defmodule MyApp.Services.SearchService do
  @moduledoc """
  Service pour gérer la recherche et le filtrage intelligent des annonces.

  Ce service combine :
  - La recherche par mots-clés
  - Le filtrage par tags multiples
  - Les suggestions de recherche
  - L'analyse de la query pour extraire automatiquement les filtres

  C'est le service qui rend la recherche "intelligente" en comprenant
  ce que l'utilisateur tape (ex: "valorant gold chill" devient automatiquement
  des filtres sur jeu=Valorant, rank=Gold, vibe=Chill).
  """

  alias MyApp.Services.AnnouncementService
  alias MyApp.Services.TagService

  # ============================================================================
  # RECHERCHE INTELLIGENTE
  # ============================================================================

  @doc """
  Effectue une recherche intelligente qui comprend la query.

  Cette fonction analyse le texte de recherche et extrait automatiquement :
  - Le jeu mentionné (ex: "valorant" → filtre par jeu Valorant)
  - Le rang mentionné (ex: "gold" → filtre par rang Gold)
  - Les tags mentionnés (ex: "chill" → ajoute #Chill aux filtres)

  ## Paramètres
    - query : Texte de recherche brut (ex: "valorant gold chill")

  ## Retour
    - Map contenant :
      - :announcements → Liste des annonces matchantes
      - :extracted_filters → Tags/filtres détectés automatiquement
      - :search_text → Texte restant après extraction des filtres

  ## Exemples

      iex> smart_search("valorant gold maintenant")
      %{
        announcements: [...],
        extracted_filters: ["#Valorant", "#Gold", "#DispoMaintenant"],
        search_text: ""
      }

      iex> smart_search("cherche support apex")
      %{
        announcements: [...],
        extracted_filters: ["#Apex"],
        search_text: "cherche support"
      }
  """
  def smart_search(query) when is_binary(query) do
    query_lower = String.downcase(query)

    # Extrait les filtres automatiquement de la query
    extracted_tags = extract_tags_from_query(query_lower)

    # Enlève les mots-clés reconnus de la query
    remaining_text = remove_extracted_keywords(query_lower)

    # Recherche avec les filtres extraits
    announcements = AnnouncementService.list_active(remaining_text, extracted_tags)

    %{
      announcements: announcements,
      extracted_filters: extracted_tags,
      search_text: remaining_text
    }
  end

  # ============================================================================
  # EXTRACTION DE TAGS DEPUIS LA QUERY
  # ============================================================================

  @doc """
  Extrait automatiquement les tags d'une query textuelle.

  Analyse le texte et détecte :
  - Les noms de jeux
  - Les rangs
  - Les mots-clés de disponibilité (maintenant, ce soir, etc.)
  - Les vibes (chill, competitive, etc.)
  - Les langues (francophone, english, etc.)

  ## Exemples

      iex> extract_tags_from_query("valorant gold chill")
      ["#Valorant", "#Gold", "#Chill"]

      iex> extract_tags_from_query("apex maintenant francophone")
      ["#Apex", "#DispoMaintenant", "#Francophone"]
  """
  def extract_tags_from_query(query_lower) do
    tags = []

    # Détecte le jeu
    tags = tags ++ detect_game(query_lower)

    # Détecte le rang
    tags = tags ++ detect_rank(query_lower)

    # Détecte la disponibilité
    tags = tags ++ detect_availability(query_lower)

    # Détecte la vibe
    tags = tags ++ detect_vibe(query_lower)

    # Détecte la langue
    tags = tags ++ detect_language(query_lower)

    # Détecte d'autres mots-clés
    tags = tags ++ detect_other_keywords(query_lower)

    Enum.uniq(tags)
  end

  # ============================================================================
  # SUGGESTIONS DE RECHERCHE
  # ============================================================================

  @doc """
  Génère des suggestions de recherche basées sur une query partielle.
  Utilisé pour l'autocomplétion dans la barre de recherche.

  ## Paramètres
    - partial_query : Début de texte tapé par l'utilisateur

  ## Retour
    - Liste de suggestions complètes

  ## Exemples

      iex> suggest("val")
      ["valorant gold", "valorant chill", "valorant ranked"]

      iex> suggest("apex")
      ["apex maintenant", "apex ranked", "apex chill"]
  """
  def suggest(partial_query) when byte_size(partial_query) < 2 do
    # Si moins de 2 caractères, retourne des suggestions populaires
    [
      "valorant gold",
      "apex chill",
      "league ranked",
      "cs2 competitive",
      "fortnite maintenant"
    ]
  end

  def suggest(partial_query) do
    query_lower = String.downcase(partial_query)

    # Suggestions basées sur les jeux populaires
    game_suggestions = suggest_games(query_lower)

    # Suggestions basées sur les combinaisons populaires
    combo_suggestions = suggest_combos(query_lower)

    (game_suggestions ++ combo_suggestions)
    |> Enum.uniq()
    |> Enum.take(5)
  end

  # ============================================================================
  # FONCTIONS PRIVÉES (DÉTECTION)
  # ============================================================================

  # Détecte le jeu dans la query
  defp detect_game(query) do
    games = TagService.get_games()

    games
    |> Enum.filter(fn game ->
      game_lower = String.downcase(game)
      String.contains?(query, game_lower)
    end)
    |> Enum.map(&"##{&1}")
  end

  # Détecte le rang dans la query
  defp detect_rank(query) do
    ranks = ["iron", "bronze", "silver", "gold", "platinum", "diamond",
             "master", "grandmaster", "challenger", "radiant", "immortal",
             "ascendant", "rookie", "predator"]

    ranks
    |> Enum.filter(&String.contains?(query, &1))
    |> Enum.map(fn rank -> "##{String.capitalize(rank)}" end)
  end

  # Détecte la disponibilité dans la query
  defp detect_availability(query) do
    cond do
      String.contains?(query, "maintenant") or String.contains?(query, "now") ->
        ["#DispoMaintenant"]

      String.contains?(query, "ce soir") or String.contains?(query, "tonight") ->
        ["#CeSoir"]

      String.contains?(query, "weekend") ->
        ["#Weekend"]

      String.contains?(query, "récurrent") or String.contains?(query, "recurring") ->
        ["#Recurrent"]

      true ->
        []
    end
  end

  # Détecte la vibe dans la query
  defp detect_vibe(query) do
    cond do
      String.contains?(query, "chill") or String.contains?(query, "relax") ->
        ["#Chill"]

      String.contains?(query, "competitive") or String.contains?(query, "comp") or
      String.contains?(query, "tryhard") or String.contains?(query, "ranked") ->
        ["#Competitive"]

      String.contains?(query, "fun") or String.contains?(query, "casual") ->
        ["#Fun"]

      String.contains?(query, "learning") or String.contains?(query, "apprentissage") ->
        ["#Learning"]

      true ->
        []
    end
  end

  # Détecte la langue dans la query
  defp detect_language(query) do
    cond do
      String.contains?(query, "francophone") or String.contains?(query, "français") or
      String.contains?(query, "french") or String.contains?(query, "fr") ->
        ["#Francophone"]

      String.contains?(query, "english") or String.contains?(query, "en") ->
        ["#English"]

      String.contains?(query, "spanish") or String.contains?(query, "español") ->
        ["#Spanish"]

      true ->
        []
    end
  end

  # Détecte d'autres mots-clés communs
  defp detect_other_keywords(query) do
    keywords = []

    keywords = if String.contains?(query, "micro"), do: keywords ++ ["#Micro"], else: keywords
    keywords = if String.contains?(query, "débutant") or String.contains?(query, "beginner"),
                  do: keywords ++ ["#BeginnerFriendly"], else: keywords
    keywords = if String.contains?(query, "coaching"), do: keywords ++ ["#Coaching"], else: keywords

    keywords
  end

  # Enlève les mots-clés détectés de la query pour ne garder que le texte libre
  defp remove_extracted_keywords(query) do
    # Liste de tous les mots-clés à retirer
    keywords_to_remove = [
      "valorant", "apex", "league", "cs2", "fortnite", "overwatch", "rocket league",
      "iron", "bronze", "silver", "gold", "platinum", "diamond", "master",
      "maintenant", "now", "ce soir", "tonight", "weekend",
      "chill", "relax", "competitive", "comp", "tryhard", "ranked", "fun", "casual",
      "francophone", "français", "french", "english", "spanish",
      "micro", "débutant", "beginner", "coaching"
    ]

    remaining = Enum.reduce(keywords_to_remove, query, fn keyword, acc ->
      String.replace(acc, keyword, "")
    end)

    remaining
    |> String.trim()
    |> String.replace(~r/\s+/, " ")  # Nettoie les espaces multiples
  end

  # Suggestions de jeux
  defp suggest_games(query) do
    TagService.get_games()
    |> Enum.filter(fn game ->
      String.starts_with?(String.downcase(game), query)
    end)
    |> Enum.map(&String.downcase/1)
  end

  # Suggestions de combinaisons populaires
  defp suggest_combos(query) do
    popular_combos = [
      "valorant gold ranked",
      "valorant chill",
      "apex ranked",
      "apex chill maintenant",
      "league ranked gold",
      "cs2 competitive",
      "fortnite fun",
      "overwatch ranked"
    ]

    popular_combos
    |> Enum.filter(&String.starts_with?(&1, query))
  end
end
