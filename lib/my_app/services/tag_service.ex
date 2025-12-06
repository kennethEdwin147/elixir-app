defmodule MyApp.Services.TagService do
  @moduledoc """
  Service pour gérer les tags des annonces.

  Ce service gère :
  - Les tags prédéfinis (jeux, rangs, vibes, langues, etc.)
  - L'autocomplétion lors de la recherche
  - La construction automatique de tags basée sur les données du formulaire
  - Les suggestions de tags populaires
  """

  # ============================================================================
  # TAGS PRÉDÉFINIS
  # ============================================================================

  @doc """
  Retourne la liste des jeux disponibles.
  """
  def get_games do
    [
      "Valorant",
      "Apex Legends",
      "League of Legends",
      "CS2",
      "Fortnite",
      "Overwatch 2",
      "Rocket League",
      "Rainbow Six Siege",
      "Minecraft",
      "Call of Duty"
    ]
  end

  @doc """
  Retourne la liste des rangs pour un jeu donné.
  Si le jeu n'est pas reconnu, retourne une liste générique.
  """
  def get_ranks(game \\ nil) do
    case game do
      "Valorant" ->
        ["Iron", "Bronze", "Silver", "Gold", "Platinum", "Diamond", "Ascendant", "Immortal", "Radiant"]

      "Apex Legends" ->
        ["Rookie", "Bronze", "Silver", "Gold", "Platinum", "Diamond", "Master", "Predator"]

      "League of Legends" ->
        ["Iron", "Bronze", "Silver", "Gold", "Platinum", "Diamond", "Master", "Grandmaster", "Challenger"]

      "CS2" ->
        ["Silver", "Gold Nova", "Master Guardian", "Legendary Eagle", "Supreme", "Global Elite"]

      _ ->
        # Rangs génériques pour les autres jeux
        ["Beginner", "Intermediate", "Advanced", "Expert"]
    end
  end

  @doc """
  Retourne tous les tags prédéfinis organisés par catégorie.
  Utilisé pour afficher les suggestions dans le formulaire.
  """
  def get_all_predefined_tags do
    %{
      availability: [
        %{value: "now", label: "Dispo maintenant", tag: "#DispoMaintenant"},
        %{value: "tonight", label: "Ce soir", tag: "#CeSoir"},
        %{value: "weekend", label: "Weekend", tag: "#Weekend"},
        %{value: "recurring", label: "Récurrent", tag: "#Recurrent"}
      ],
      vibe: [
        %{value: "chill", label: "Chill", tag: "#Chill"},
        %{value: "competitive", label: "Compétitif", tag: "#Competitive"},
        %{value: "fun", label: "Fun", tag: "#Fun"},
        %{value: "learning", label: "Apprentissage", tag: "#Learning"}
      ],
      communication: [
        %{label: "Micro", tag: "#Micro"},
        %{label: "Texte seulement", tag: "#TextOnly"},
        %{label: "Vocal optionnel", tag: "#VoiceOptional"}
      ],
      language: [
        %{label: "Francophone", tag: "#Francophone"},
        %{label: "English", tag: "#English"},
        %{label: "Spanish", tag: "#Spanish"},
        %{label: "Portuguese", tag: "#Portuguese"}
      ],
      other: [
        %{label: "18+", tag: "#18+"},
        %{label: "Débutant friendly", tag: "#BeginnerFriendly"},
        %{label: "No drama", tag: "#NoDrama"},
        %{label: "LGBTQ+ friendly", tag: "#LGBTQFriendly"},
        %{label: "Coaching", tag: "#Coaching"},
        %{label: "Long session", tag: "#LongSession"}
      ]
    }
  end

  # ============================================================================
  # CONSTRUCTION AUTOMATIQUE DE TAGS
  # ============================================================================

  @doc """
  Construit automatiquement la liste de tags basée sur les paramètres du formulaire.

  Prend les données du formulaire (jeu, rang, dispo, vibe) et génère les tags correspondants.
  Les tags manuels sont ajoutés à la fin.

  ## Exemples

      iex> build_tags(%{"game" => "Valorant", "rank" => "Gold", "availability" => "now"})
      ["#Valorant", "#Gold", "#DispoMaintenant"]

      iex> build_tags(%{"game" => "Apex", "vibe" => "chill", "tags" => ["#Francophone"]})
      ["#Apex", "#Chill", "#Francophone"]
  """
  def build_tags(params) do
    tags = []

    # Ajoute le tag du jeu
    tags = if params["game"], do: tags ++ ["##{params["game"]}"], else: tags

    # Ajoute le tag du rang
    tags = if params["rank"], do: tags ++ ["##{params["rank"]}"], else: tags

    # Ajoute le tag de disponibilité
    tags = case params["availability"] do
      "now" -> tags ++ ["#DispoMaintenant"]
      "tonight" -> tags ++ ["#CeSoir"]
      "weekend" -> tags ++ ["#Weekend"]
      "recurring" -> tags ++ ["#Recurrent"]
      _ -> tags
    end

    # Ajoute le tag de vibe
    tags = case params["vibe"] do
      "chill" -> tags ++ ["#Chill"]
      "competitive" -> tags ++ ["#Competitive"]
      "fun" -> tags ++ ["#Fun"]
      "learning" -> tags ++ ["#Learning"]
      _ -> tags
    end

    # Ajoute les tags manuels fournis par l'utilisateur
    manual_tags = params["tags"] || []
    tags = tags ++ manual_tags

    # Retire les doublons et retourne
    Enum.uniq(tags)
  end

  # ============================================================================
  # RECHERCHE ET AUTOCOMPLÉTION
  # ============================================================================

  @doc """
  Recherche des tags correspondant à une query.
  Utilisé pour l'autocomplétion dans la barre de recherche.

  ## Exemples

      iex> search_tags("chi")
      [
        %{tag: "#Chill", category: "vibe", usage_count: 245},
        %{tag: "#Coaching", category: "other", usage_count: 12}
      ]

      iex> search_tags("val")
      [%{tag: "#Valorant", category: "game", usage_count: 892}]
  """
  def search_tags(query) when byte_size(query) < 2 do
    # Si moins de 2 caractères, retourne les tags populaires
    get_popular_tags()
  end

  def search_tags(query) do
    query_lower = String.downcase(query)

    # Récupère tous les tags prédéfinis
    all_tags = get_all_tags_flat()

    # Filtre ceux qui matchent la query
    all_tags
    |> Enum.filter(fn tag_map ->
      tag_lower = String.downcase(tag_map.tag)
      String.contains?(tag_lower, query_lower)
    end)
    |> Enum.sort_by(& &1.usage_count, :desc)
    |> Enum.take(10)  # Limite à 10 suggestions
  end

  @doc """
  Retourne les tags les plus populaires.
  Basé sur un comptage fictif pour le MVP, mais devrait être remplacé
  par une vraie requête SQL comptant les usages dans la table announcements.
  """
  def get_popular_tags do
    [
      %{tag: "#DispoMaintenant", category: "availability", usage_count: 524},
      %{tag: "#Valorant", category: "game", usage_count: 892},
      %{tag: "#Chill", category: "vibe", usage_count: 445},
      %{tag: "#Francophone", category: "language", usage_count: 387},
      %{tag: "#Gold", category: "rank", usage_count: 312},
      %{tag: "#Apex", category: "game", usage_count: 298},
      %{tag: "#Competitive", category: "vibe", usage_count: 267},
      %{tag: "#Micro", category: "communication", usage_count: 234}
    ]
  end

  # ============================================================================
  # FONCTIONS PRIVÉES (HELPERS)
  # ============================================================================

  # Convertit tous les tags prédéfinis en une liste plate pour la recherche
  defp get_all_tags_flat do
    predefined = get_all_predefined_tags()
    games = get_games() |> Enum.map(&%{tag: "##{&1}", category: "game", usage_count: 100})
    ranks = get_ranks() |> Enum.map(&%{tag: "##{&1}", category: "rank", usage_count: 50})

    availability_tags = predefined.availability |> Enum.map(&Map.put(&1, :usage_count, 200))
    vibe_tags = predefined.vibe |> Enum.map(&Map.put(&1, :usage_count, 150))
    comm_tags = predefined.communication |> Enum.map(&Map.put(&1, :usage_count, 100))
    lang_tags = predefined.language |> Enum.map(&Map.put(&1, :usage_count, 120))
    other_tags = predefined.other |> Enum.map(&Map.put(&1, :usage_count, 80))

    games ++ ranks ++
    Enum.map(availability_tags, &%{tag: &1.tag, category: "availability", usage_count: &1.usage_count}) ++
    Enum.map(vibe_tags, &%{tag: &1.tag, category: "vibe", usage_count: &1.usage_count}) ++
    Enum.map(comm_tags, &%{tag: &1.tag, category: "communication", usage_count: &1.usage_count}) ++
    Enum.map(lang_tags, &%{tag: &1.tag, category: "language", usage_count: &1.usage_count}) ++
    Enum.map(other_tags, &%{tag: &1.tag, category: "other", usage_count: &1.usage_count})
  end
end
