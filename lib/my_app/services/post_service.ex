defmodule MyApp.Services.PostService do
  @moduledoc """
  Service pour gérer les posts LFG (MVP minimaliste).
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.Post

  # ============================================================================
  # CRÉATION DE POSTS
  # ============================================================================

  @doc """
  Crée un nouveau post.
  """
  def create(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  # ============================================================================
  # RÉCUPÉRATION DE POSTS
  # ============================================================================

  @doc """
  Liste tous les posts actifs pour un jeu donné.
  Triés par score (HN-style ranking).
  """
  def list_active(game_slug) do
    Post
    |> where([p], p.game == ^game_slug and p.active == true)
    |> order_by([p], desc: p.score)
    |> preload(:user)
    |> Repo.all()
    |> Enum.map(&add_time_ago/1)
    |> Enum.map(&add_comment_count/1)  # ← AJOUTE
  end

 def list_recent(limit \\ 10) do
  import Ecto.Query

  Post
  |> where([p], p.active == true)
  |> where([p], p.game == "valorant")
  |> order_by([p], desc: p.inserted_at)
  |> limit(^limit)
  |> preload(:user)
  |> Repo.all()
  |> Enum.map(&decode_tags/1)        # ← AJOUTE
  |> Enum.map(&add_time_ago/1)       # ← AJOUTE
  |> Enum.map(&add_comment_count/1)  # ← AJOUTE
end

  @doc """
  Récupère un post par ID.
  """
  def get(id) do
    Repo.get(Post, id)
    |> Repo.preload(:user)
  end

  @doc """
  Liste les posts d'un utilisateur.
  """
  def list_by_user(user_id) do
    Post
    |> where([p], p.user_id == ^user_id)
    |> order_by([p], desc: p.inserted_at)
    |> Repo.all()
    |> Enum.map(&decode_tags/1)
  end

  # ============================================================================
  # VOTE
  # ============================================================================

  @doc """
  Incrémente le score d'un post (upvote simple, pas de tracking pour MVP).
  """
  def upvote(post_id) do
    case get(post_id) do
      nil ->
        {:error, :not_found}

      post ->
        post
        |> Ecto.Changeset.change(%{score: post.score + 1})
        |> Repo.update()
    end
  end

  # ============================================================================
  # SUPPRESSION
  # ============================================================================

  @doc """
  Supprime un post (vérifie ownership).
  """
  def delete(post_id, user_id) do
  case get(post_id) do
    nil ->
      {:error, :not_found}
    post ->
      if post.user_id == user_id do
        post
        |> Ecto.Changeset.change(%{active: false})  # ← Soft delete
        |> Repo.update()
      else
          {:error, :unauthorized}
        end
    end
  end

  # ============================================================================
  # HELPERS PRIVÉS
  # ============================================================================

  def decode_tags(post) do
    tags = case post.tags do
      tags when is_binary(tags) ->
        case Jason.decode(tags) do
          {:ok, list} -> list
          _ -> []
        end
      _ -> []
    end

    Map.put(post, :tags, tags)
  end

  def add_time_ago(post) do
    Map.put(post, :time_ago, calculate_time_ago(post.inserted_at))
  end

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

  # Ajoute cette fonction privée à la fin du fichier
  defp add_comment_count(post) do
    count = Repo.one(
      from c in MyApp.Schemas.Comment,
      where: c.post_id == ^post.id,
      select: count(c.id)
    )

    Map.put(post, :comment_count, count)
  end

end
