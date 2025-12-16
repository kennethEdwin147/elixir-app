defmodule MyApp.Services.GameCatalogService  do

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
  def get_stats(slug) do
    alias MyApp.Repo
    alias MyApp.Schemas.Announcement
    import Ecto.Query

    # Compter annonces actives
    active_count = Repo.one(
      from a in Announcement,
      where: a.game == ^slug and a.active == true,
      select: count(a.id)
    ) || 0

    # Compter annonces cette semaine
    week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    week_count = Repo.one(
      from a in Announcement,
      where: a.game == ^slug and a.inserted_at > ^week_ago,
      select: count(a.id)
    ) || 0

    %{
      active_announcements: active_count,
      week_announcements: week_count,
      active_players: active_count * 2 # Estimation
    }
  end
end
