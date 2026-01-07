defmodule MyApp.Contexts.Game do
  @moduledoc """
  Service pour gérer les jeux disponibles dans l'application.

  ## Récupération
  - list_active()           # Jeux actifs
  - list_all()              # Tous les jeux
  - get_by_slug(slug)       # Récupère par slug
  - get(id)                 # Récupère par ID
  - exists?(slug)           # Vérifie existence

  ## Création & Modification
  - create(attrs)           # Créer un jeu
  - update_game(id, attrs)  # Modifier
  - activate(id)            # Activer
  - deactivate(id)          # Désactiver

  ## Helpers
  - get_metadata(slug)      # Icône, couleur, nom complet
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.Game

  # ============================================================================
  # RÉCUPÉRATION
  # ============================================================================

  @doc """
  Liste tous les jeux actifs.
  """
  def list_active do
    Game
    |> where([g], g.active == true)
    |> order_by([g], asc: g.name)
    |> Repo.all()
  end

  @doc """
  Liste tous les jeux (actifs et inactifs).
  """
  def list_all do
    Game
    |> order_by([g], asc: g.name)
    |> Repo.all()
  end

  @doc """
  Récupère un jeu par son slug.
  Retourne nil si non trouvé.
  """
  def get_by_slug(slug) when is_binary(slug) do
    Game
    |> where([g], g.slug == ^slug)
    |> Repo.one()
  end

  @doc """
  Récupère un jeu par son ID.
  """
  def get(id) do
    Repo.get(Game, id)
  end

  @doc """
  Vérifie si un jeu existe par slug.
  """
  def exists?(slug) when is_binary(slug) do
    Game
    |> where([g], g.slug == ^slug)
    |> Repo.exists?()
  end

  # ============================================================================
  # CRÉATION & MODIFICATION
  # ============================================================================

  @doc """
  Crée un nouveau jeu.

  ## Exemples
      iex> create(%{slug: "valorant", name: "Valorant"})
      {:ok, %Game{}}
  """
  def create(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Met à jour un jeu.
  """
  def update_game(id, attrs) do
    case get(id) do
      nil ->
        {:error, :not_found}

      game ->
        game
        |> Game.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Active un jeu.
  """
  def activate(id) do
    update_game(id, %{active: true})
  end

  @doc """
  Désactive un jeu.
  """
  def deactivate(id) do
    update_game(id, %{active: false})
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  @doc """
  Retourne une map de metadata pour un jeu (icône, couleur, etc.).
  Utile pour l'affichage dans les templates.
  """
  def get_metadata(slug) do
    case slug do
      "valorant" ->
        %{
          icon: "🎯",
          color: "#FF4655",
          full_name: "VALORANT"
        }

      "apex" ->
        %{
          icon: "🎮",
          color: "#DA292E",
          full_name: "Apex Legends"
        }

      "cs2" ->
        %{
          icon: "🔫",
          color: "#F0B323",
          full_name: "Counter-Strike 2"
        }

      "lol" ->
        %{
          icon: "⚔️",
          color: "#0AC8B9",
          full_name: "League of Legends"
        }

      "overwatch" ->
        %{
          icon: "🦸",
          color: "#FA9C1E",
          full_name: "Overwatch 2"
        }

      _ ->
        %{
          icon: "🎮",
          color: "#666666",
          full_name: slug
        }
    end
  end
end
