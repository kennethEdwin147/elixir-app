defmodule MyApp.Services.AnnouncementService do
  @moduledoc """
  Service pour gérer les annonces (CRUD + logique métier).

  Ce service gère :
  - La création d'annonces
  - La récupération des annonces actives avec filtres
  - La recherche et le filtrage par tags/mots-clés
  - La complétion et suppression d'annonces
  - Le cleanup automatique des annonces expirées
  - L'engagement (upvotes, interested)
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.{Announcement, Upvote, Interested}

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
    - search_query : Texte de recherche (optionnel, recherche dans description)
    - selected_tags : Liste de tags pour filtrer (optionnel)
    - selected_game : Slug du jeu pour filtrer (optionnel, ex: "valorant")

  ## Retour
    - Liste d'annonces triées par date (plus récentes en premier)

  ## Exemples

      iex> list_active()
      [%Announcement{}, %Announcement{}, ...]

      iex> list_active("duo", ["ranked"], "valorant")
      [%Announcement{game: "valorant", description: "LF duo...", tags: ["ranked"]}, ...]
  """
  # lib/my_app/services/announcement_service.ex
  # lib/my_app/services/announcement_service.ex

def list_active(search_query \\ "", selected_tags \\ [], selected_game \\ nil) do
  query = from a in Announcement,
    where: a.active == true,
    order_by: [desc: a.inserted_at],
    preload: :user

  # ========================================
  # ENLEVER CE BLOC COMPLÈTEMENT
  # ========================================
  # query = if search_query != "" do
  #   search_pattern = "%#{search_query}%"
  #   from a in query,
  #     where: like(a.description, ^search_pattern)
  # else
  #   query
  # end

  # ========================================
  # GARDER SEULEMENT CE BLOC POUR RECHERCHE
  # ========================================
  query = if search_query != "" do
    search_pattern = "%#{search_query}%"
    from a in query,
      where:
        like(a.description, ^search_pattern) or
        like(a.game, ^search_pattern) or
        like(a.rank, ^search_pattern) or
        like(a.vibe, ^search_pattern)
  else
    query
  end

  # Filtre par tags
  query = if selected_tags != [] && length(selected_tags) > 0 do
    Enum.reduce(selected_tags, query, fn tag, q ->
      search_pattern = "%\"#{tag}\"%"
      from a in q,
        where: like(a.tags, ^search_pattern)
    end)
  else
    query
  end

  # Filtre par jeu (selected_game)
  query = if selected_game do
    from a in query,
      where: a.game == ^selected_game
  else
    query
  end

  Repo.all(query)
  |> Enum.map(&decode_tags/1)
end


  # Ajouter cette fonction à la fin du module
  defp decode_tags(announcement) do
    tags = case announcement.tags do
      tags when is_binary(tags) ->
        case Jason.decode(tags) do
          {:ok, list} -> list
          _ -> []
        end
      _ -> []
    end

    Map.put(announcement, :tags, tags)
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
  # ENGAGEMENT (UPVOTE / INTERESTED)
  # ============================================================================

  @doc """
  Toggle upvote : ajoute si pas encore upvoté, enlève si déjà upvoté.

  ## Paramètres
    - announcement_id : ID de l'annonce
    - user_id : ID de l'utilisateur

  ## Retour
    - {:ok, :added} si upvote ajouté
    - {:ok, :removed} si upvote enlevé
    - {:error, :not_found} si annonce inexistante
  """
  def toggle_upvote(announcement_id, user_id) do
    case get(announcement_id) do
      nil ->
        {:error, :not_found}

      announcement ->
        # Cherche si upvote existe déjà
        existing_upvote = Repo.get_by(Upvote,
          user_id: user_id,
          announcement_id: announcement_id
        )

        case existing_upvote do
          nil ->
            # Pas encore upvoté → Ajouter
            %Upvote{}
            |> Upvote.changeset(%{user_id: user_id, announcement_id: announcement_id})
            |> Repo.insert()

            # Incrémenter le count
            announcement
            |> Ecto.Changeset.change(%{upvotes_count: announcement.upvotes_count + 1})
            |> Repo.update()

            {:ok, :added}

          upvote ->
            # Déjà upvoté → Enlever
            Repo.delete(upvote)

            # Décrémenter le count
            announcement
            |> Ecto.Changeset.change(%{upvotes_count: max(0, announcement.upvotes_count - 1)})
            |> Repo.update()

            {:ok, :removed}
        end
    end
  end

  @doc """
  Toggle interested : ajoute si pas encore interested, enlève si déjà interested.

  ## Paramètres
    - announcement_id : ID de l'annonce
    - user_id : ID de l'utilisateur

  ## Retour
    - {:ok, :added} si interested ajouté
    - {:ok, :removed} si interested enlevé
    - {:error, :not_found} si annonce inexistante
  """
  def toggle_interested(announcement_id, user_id) do
    case get(announcement_id) do
      nil ->
        {:error, :not_found}

      announcement ->
        # Cherche si interested existe déjà
        existing_interested = Repo.get_by(Interested,
          user_id: user_id,
          announcement_id: announcement_id
        )

        case existing_interested do
          nil ->
            # Pas encore interested → Ajouter
            %Interested{}
            |> Interested.changeset(%{user_id: user_id, announcement_id: announcement_id})
            |> Repo.insert()

            # Incrémenter le count
            announcement
            |> Ecto.Changeset.change(%{interested_count: announcement.interested_count + 1})
            |> Repo.update()

            {:ok, :added}

          interested ->
            # Déjà interested → Enlever
            Repo.delete(interested)

            # Décrémenter le count
            announcement
            |> Ecto.Changeset.change(%{interested_count: max(0, announcement.interested_count - 1)})
            |> Repo.update()

            {:ok, :removed}
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


  # ==========================================
  # NOUVELLE FONCTION: Liste par jeu
  # ==========================================

  def list_by_game(slug) do
    Repo.all(
      from a in Announcement,
      where: a.game == ^slug and a.active == true,
      order_by: [desc: a.inserted_at],
      preload: :user
    )
    |> Enum.map(&add_time_ago/1)
  end


   # Helper pour ajouter time_ago
  defp add_time_ago(announcement) do
    Map.put(announcement, :time_ago, calculate_time_ago(announcement.inserted_at))
  end

  defp calculate_time_ago(naive_datetime) do
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")  # ← AJOUTER CETTE LIGNE

    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}min ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end


end
