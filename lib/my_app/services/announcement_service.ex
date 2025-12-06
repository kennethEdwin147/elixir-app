defmodule MyApp.Services.AnnouncementService do
  @moduledoc """
  Service pour gérer les annonces (CRUD + logique métier).

  Ce service gère :
  - La création d'annonces
  - La récupération des annonces actives avec filtres
  - La recherche et le filtrage par tags/mots-clés
  - La complétion et suppression d'annonces
  - Le cleanup automatique des annonces expirées
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.Announcement

  # ============================================================================
  # CRÉATION D'ANNONCES
  # ============================================================================

  @doc """
  Crée une nouvelle annonce.

  ## Paramètres
    - attrs : Map contenant les champs de l'annonce (game, rank, availability, etc.)

  ## Retour
    - {:ok, announcement} si création réussie
    - {:error, changeset} si erreur de validation

  ## Exemples

      iex> create(%{
        "game" => "Valorant",
        "rank" => "Gold",
        "availability" => "now",
        "discord_contact" => "user#1234",
        "user_id" => 1
      })
      {:ok, %Announcement{...}}
  """
  def create(attrs) do
    %Announcement{}
    |> Announcement.changeset(attrs)
    |> Repo.insert()
  end

  # ============================================================================
  # RÉCUPÉRATION D'ANNONCES
  # ============================================================================

  @doc """
  Liste toutes les annonces actives avec filtres optionnels.

  ## Paramètres
    - search_query : Texte de recherche (optionnel, recherche dans game/description)
    - selected_tags : Liste de tags pour filtrer (optionnel)

  ## Retour
    - Liste d'annonces triées par date (plus récentes en premier)

  ## Exemples

      iex> list_active()
      [%Announcement{}, %Announcement{}, ...]

      iex> list_active("valorant", ["#Gold", "#Chill"])
      [%Announcement{game: "Valorant", tags: ["#Gold", "#Chill"]}, ...]
  """
   def list_active(search_query \\ "", selected_tags \\ []) do
    Announcement
    |> where([a], a.active == true)
    |> where([a], a.expires_at > ^DateTime.utc_now())
    |> filter_by_search(search_query)
    |> filter_by_tags(selected_tags)
    |> order_by([a], desc: a.inserted_at)
    |> preload(:user)
    |> Repo.all()
    |> Enum.map(&Announcement.decode_tags/1)  # Decode les tags après fetch
  end

  @doc """
  Récupère une annonce par son ID.

  ## Retour
    - %Announcement{} si trouvée
    - nil si non trouvée
  """
  def get(id) do
    Repo.get(Announcement, id)
    |> Repo.preload(:user)
  end

  @doc """
  Récupère toutes les annonces d'un utilisateur spécifique.
  Utile pour afficher "Mes annonces" dans le dashboard.

  ## Paramètres
    - user_id : ID de l'utilisateur

  ## Retour
    - Liste d'annonces de cet utilisateur
  """
  def list_by_user(user_id) do
    Announcement
    |> where([a], a.user_id == ^user_id)
    |> order_by([a], desc: a.inserted_at)
    |> Repo.all()
  end

  # ============================================================================
  # MISE À JOUR ET SUPPRESSION
  # ============================================================================

  @doc """
  Marque une annonce comme terminée (active = false).
  Vérifie que l'utilisateur est bien le propriétaire.

  ## Paramètres
    - announcement_id : ID de l'annonce
    - user_id : ID de l'utilisateur faisant la demande

  ## Retour
    - {:ok, announcement} si succès
    - {:error, :not_found} si annonce inexistante
    - {:error, :unauthorized} si pas le propriétaire
  """
  def mark_complete(announcement_id, user_id) do
    case get(announcement_id) do
      nil ->
        {:error, :not_found}

      announcement ->
        if announcement.user_id == user_id do
          announcement
          |> Announcement.complete_changeset()
          |> Repo.update()
        else
          {:error, :unauthorized}
        end
    end
  end

  @doc """
  Supprime une annonce.
  Vérifie que l'utilisateur est bien le propriétaire.

  ## Paramètres
    - announcement_id : ID de l'annonce
    - user_id : ID de l'utilisateur faisant la demande

  ## Retour
    - {:ok, announcement} si suppression réussie
    - {:error, :not_found} si annonce inexistante
    - {:error, :unauthorized} si pas le propriétaire
  """
  def delete(announcement_id, user_id) do
    case get(announcement_id) do
      nil ->
        {:error, :not_found}

      announcement ->
        if announcement.user_id == user_id do
          Repo.delete(announcement)
        else
          {:error, :unauthorized}
        end
    end
  end

  # ============================================================================
  # CLEANUP AUTOMATIQUE
  # ============================================================================

  @doc """
  Supprime toutes les annonces expirées (expires_at < maintenant).
  Devrait être appelé par un job cron ou scheduler régulier.

  ## Retour
    - {nombre_supprimé, nil}
  """
  def cleanup_expired do
    Announcement
    |> where([a], a.expires_at < ^DateTime.utc_now())
    |> Repo.delete_all()
  end

  # ============================================================================
  # FONCTIONS PRIVÉES (FILTRAGE)
  # ============================================================================

  # Filtre par recherche textuelle (game ou description contient le texte)
  defp filter_by_search(query, "") do
    query
  end

  defp filter_by_search(query, search_text) do
    search_pattern = "%#{String.downcase(search_text)}%"

    query
    |> where([a],
      fragment("LOWER(?) LIKE ?", a.game, ^search_pattern) or
      fragment("LOWER(?) LIKE ?", a.description, ^search_pattern)
    )
  end

  # Filtre par tags (l'annonce doit contenir TOUS les tags sélectionnés)
  defp filter_by_tags(query, []) do
    query
  end

  defp filter_by_tags(query, selected_tags) when is_list(selected_tags) do
    # MySQL : recherche dans le JSON texte
    Enum.reduce(selected_tags, query, fn tag, q ->
      where(q, [a], fragment("JSON_CONTAINS(?, ?)", a.tags, ^Jason.encode!(tag)))
    end)
  end
end
