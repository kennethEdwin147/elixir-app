defmodule MyApp.Games.Valorant do
  @moduledoc """
  Données spécifiques à Valorant (ranks, agents, régions, vibe tags).
  Utilisé pour les formulaires d'onboarding et les filtres.
  """

  @doc """
  Liste des ranks Valorant (Fer → Radiant).
  """
  def ranks do
    [
      "Fer 1", "Fer 2", "Fer 3",
      "Bronze 1", "Bronze 2", "Bronze 3",
      "Argent 1", "Argent 2", "Argent 3",
      "Or 1", "Or 2", "Or 3",
      "Platine 1", "Platine 2", "Platine 3",
      "Diamant 1", "Diamant 2", "Diamant 3",
      "Ascendant 1", "Ascendant 2", "Ascendant 3",
      "Immortel 1", "Immortel 2", "Immortel 3",
      "Radiant"
    ]
  end

  @doc """
  Liste complète des agents Valorant (mise à jour Épisode 9).
  """
  def agents do
    [
      # Controllers
      "Brimstone", "Viper", "Omen", "Astra", "Harbor",
      # Sentinels
      "Killjoy", "Cypher", "Sage", "Chamber", "Deadlock",
      # Initiators
      "Sova", "Breach", "Skye", "KAY/O", "Fade", "Gekko",
      # Duelists
      "Phoenix", "Jett", "Reyna", "Raze", "Yoru", "Neon", "Iso", "Clove",
      # Nouveau
      "Vyse"
    ]
    |> Enum.sort()
  end

  @doc """
  Régions de jeu Valorant.
  """
  def regions do
    ["EU West", "EU East", "NA", "LATAM", "BR", "ASIA", "OCE"]
  end

  @doc """
  Tags de vibe/style de jeu pour matching.
  """
  def vibe_tags do
    [
      "Mic ON obligatoire",
      "Chill & Fun",
      "Tryhard",
      "Ranked seulement",
      "Unrated & Swift",
      "Flex tous rôles",
      "One-trick",
      "Shotcaller",
      "Support player",
      "Lurker",
      "Entry fragger",
      "IGL (In-Game Leader)"
    ]
  end

  @doc """
  Playstyles disponibles.
  """
  def playstyles do
    [
      {"tryhard", "Tryhard - Je veux rank up"},
      {"chill", "Chill - Pour le fun"},
      {"mix", "Mix - Ça dépend de l'humeur"}
    ]
  end

  @doc """
  Tranches d'âge.
  """
  def age_ranges do
    ["18-24", "25-30", "30+"]
  end
end
