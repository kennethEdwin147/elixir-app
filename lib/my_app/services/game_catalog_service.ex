defmodule MyApp.Services.GameCatalogService do

  # Liste hardcodée des jeux supportés
  @games [
    %{
      slug: "valorant",
      name: "Valorant",
      icon: "🎯",
      color: "#FF4655"
    },
    %{
      slug: "league",
      name: "League of Legends",
      icon: "⚔️",
      color: "#0AC8B9"
    },
    %{
      slug: "apex",
      name: "Apex Legends",
      icon: "🎮",
      color: "#FF3333"
    },
    %{
      slug: "fortnite",
      name: "Fortnite",
      icon: "🏗️",
      color: "#7B68EE"
    },
    %{
      slug: "cs2",
      name: "Counter-Strike 2",
      icon: "🔫",
      color: "#F7B731"
    }
  ]

  # Retourner tous les jeux
  def all do
    @games
  end

  # Trouver un jeu par slug
  def get_by_slug(slug) do
    Enum.find(@games, fn game -> game.slug == slug end)
  end

  # Stats pour un jeu
  # Stats pour un jeu
  def get_stats(slug) do
    alias MyApp.Repo
    alias MyApp.Schemas.Post  # ← CHANGE ICI
    import Ecto.Query

    # Compter posts actifs
    active_count = Repo.one(
      from p in Post,  # ← CHANGE ICI
      where: p.game == ^slug and p.active == true,
      select: count(p.id)
    ) || 0

    # Compter posts cette semaine
    week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    week_count = Repo.one(
      from p in Post,  # ← CHANGE ICI
      where: p.game == ^slug and p.inserted_at > ^week_ago,
      select: count(p.id)
    ) || 0

    %{
      active_posts: active_count,
      week_posts: week_count,
      active_players: active_count * 2
    }
  end  # ← CHANGE ICI
end
