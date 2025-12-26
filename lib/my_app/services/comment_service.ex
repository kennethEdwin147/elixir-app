defmodule MyApp.Services.CommentService do
  @moduledoc """
  Service pour gérer les commentaires avec support de threading (commentaires imbriqués).
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.Comment

  # ============================================================================
  # RÉCUPÉRATION COMMENTAIRE
  # ============================================================================

  def get(id) do
    Repo.get(Comment, id)
    |> Repo.preload(:user)
  end

  # ============================================================================
  # SUPPRESSION COMMENTAIRE
  # ============================================================================

  def delete(comment_id) do
    case get(comment_id) do
      nil -> {:error, :not_found}
      comment -> Repo.delete(comment)
    end
  end

  # ============================================================================
  # CRÉATION DE COMMENTAIRE
  # ============================================================================

  @doc """
  Crée un nouveau commentaire.

  attrs doit contenir:
  - body: texte du commentaire
  - user_id: ID de l'auteur
  - post_id: ID du post
  - parent_id (optionnel): ID du commentaire parent si c'est une réponse
  """
  def create(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  # ============================================================================
  # RÉCUPÉRATION DES COMMENTAIRES
  # ============================================================================

  @doc """
  Récupère tous les commentaires d'un post et les structure en arbre hiérarchique.

  Retourne une liste de commentaires parents, chacun ayant un champ :replies
  contenant ses réponses.

  Structure:
  [
    %Comment{id: 1, body: "Question?", replies: [
      %Comment{id: 2, body: "Réponse!", parent_id: 1}
    ]},
    %Comment{id: 3, body: "Autre commentaire", replies: []}
  ]
  """
  def list_by_post(post_id) do
    comments = Comment
    |> where([c], c.post_id == ^post_id)
    |> order_by([c], asc: c.inserted_at)
    |> preload(:user)
    |> Repo.all()
    |> Enum.map(&add_time_ago/1)

    build_tree(comments)
  end

  # ============================================================================
  # CONSTRUCTION DE L'ARBRE HIÉRARCHIQUE
  # ============================================================================

  # Transforme une liste plate de commentaires en structure hiérarchique.
  # Sépare parents (parent_id = nil) et attache les réponses à chaque parent.
  # MVP: 1 seul niveau d'imbrication (pas de reply sur reply).
  defp build_tree(comments) do
    {parents, replies} = Enum.split_with(comments, fn c -> is_nil(c.parent_id) end)

    Enum.map(parents, fn parent ->
      children = Enum.filter(replies, fn reply ->
        reply.parent_id == parent.id
      end)

      Map.put(parent, :replies, children)
    end)
  end

  # ============================================================================
  # HELPERS PRIVÉS
  # ============================================================================

  # Ajoute un champ :time_ago avec le temps écoulé en français.
  # Ex: "il y a 5min", "il y a 2h", "il y a 3j"
  defp add_time_ago(comment) do
    Map.put(comment, :time_ago, calculate_time_ago(comment.inserted_at))
  end

  # Calcule le temps écoulé depuis la création du commentaire.
  # Retourne une string formatée en français.
  defp calculate_time_ago(naive_datetime) do
    datetime = DateTime.from_naive!(naive_datetime, "Etc/UTC")
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "il y a #{diff}s"
      diff < 3600 -> "il y a #{div(diff, 60)}min"
      diff < 86400 -> "il y a #{div(diff, 3600)}h"
      true -> "il y a #{div(diff, 86400)}j"
    end
  end
end
