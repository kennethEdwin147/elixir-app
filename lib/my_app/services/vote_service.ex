defmodule MyApp.Services.VoteService do
  @moduledoc """
  Service pour gérer les votes (upvotes/downvotes) avec système de toggle.
  Un user peut voter une seule fois par post/comment.
  Re-cliquer retire le vote.
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.{Vote, Post, Comment}

  # ============================================================================
  # TOGGLE VOTE (ajoute ou retire)
  # ============================================================================

  @doc """
  Toggle un vote pour un post ou commentaire.

  Si le vote existe déjà → le retire (score -1)
  Si le vote n'existe pas → l'ajoute (score +1)

  Retourne {:ok, :added} ou {:ok, :removed}
  """
  def toggle_vote(user_id, votable_type, votable_id) do
    # Cherche si vote existe
    vote = Repo.get_by(Vote,
      user_id: user_id,
      votable_type: votable_type,
      votable_id: votable_id
    )

    case vote do
      # Vote existe → RETIRE
      %Vote{} = existing_vote ->
        Repo.delete(existing_vote)
        decrement_score(votable_type, votable_id)
        {:ok, :removed}

      # Vote n'existe pas → AJOUTE
      nil ->
        %Vote{}
        |> Vote.changeset(%{
          user_id: user_id,
          votable_type: votable_type,
          votable_id: votable_id,
          value: 1
        })
        |> Repo.insert()

        increment_score(votable_type, votable_id)
        {:ok, :added}
    end
  end

  # ============================================================================
  # VÉRIFIER SI USER A VOTÉ
  # ============================================================================

  @doc """
  Vérifie si un user a déjà voté pour un item.
  Retourne true/false.
  """
  def has_voted?(nil, _votable_type, _votable_id), do: false

  def has_voted?(user_id, votable_type, votable_id) when is_integer(user_id) do
    Repo.exists?(
      from v in Vote,
      where: v.user_id == ^user_id and
             v.votable_type == ^votable_type and
             v.votable_id == ^votable_id
    )
  end

  def has_voted?(%{id: user_id}, votable_type, votable_id) do
    has_voted?(user_id, votable_type, votable_id)
  end

  # ============================================================================
  # HELPERS PRIVÉS
  # ============================================================================

  # Incrémente le score
  defp increment_score("post", post_id) do
    from(p in Post, where: p.id == ^post_id)
    |> Repo.update_all(inc: [score: 1])
  end

  defp increment_score("comment", comment_id) do
    from(c in Comment, where: c.id == ^comment_id)
    |> Repo.update_all(inc: [score: 1])
  end

  # Décrémente le score
  defp decrement_score("post", post_id) do
    from(p in Post, where: p.id == ^post_id)
    |> Repo.update_all(inc: [score: -1])
  end

  defp decrement_score("comment", comment_id) do
    from(c in Comment, where: c.id == ^comment_id)
    |> Repo.update_all(inc: [score: -1])
  end
end
