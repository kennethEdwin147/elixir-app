defmodule MyApp.Controllers.GameFeedController do
  use Plug.Router
  require EEx

  alias MyApp.Services.{PostService, GameCatalogService, Validator, CommentService, Policy, VoteService}
  plug :match
  plug :dispatch

  # Routes:
  # GET  /g/test/post              → Route de test (SUPPRIMER EN PROD)
  # GET  /g/:slug                  → Feed du jeu
  # GET  /g/:slug/submit           → Formulaire création post
  # POST /g/:slug/posts            → Créer post
  # GET  /g/:slug/posts/:id        → Détail post + commentaires
  # POST /g/:slug/posts/:id/upvote → Upvote post
  # POST /g/:slug/posts/:id/delete → Supprimer post (PROTÉGÉ + ownership)
  # POST /g/:slug/posts/:id/comments → Créer commentaire
  # POST /g/:slug/posts/:id/comments/:cid/delete → Supprimer commentaire (PROTÉGÉ + ownership)

  # ============================================================================
  # ROUTE DE TEST (SUPPRIMER EN PROD)
  # http://localhost:4000/g/test/post
  # ============================================================================

  get "/test/post" do
    # Fake game
    game = %{slug: "valorant", name: "Valorant", icon: "🎯", color: "#FF4655"}

    # Fake post
    post = %{
      id: 1,
      type: "lfg",
      game: "valorant",
      rank: "Platine 2",
      region: "EU",
      description: "Jett main cherche duo ranked chill, pas de toxic. Objectif Diamant avant la fin de la saison. Je joue surtout le soir après 20h.",
      contact: "Discord: JettMain#1234",
      score: 12,
      time_ago: "il y a 5min",
      tags: ["chill", "ranked", "vocal"],
      url: nil,
      user: %{id: 1, username: "player1", email: "test@test.com"}
    }

    # Fake comments
    comments = [
      %{
        id: 1,
        body: "Tu joues à quelle heure exactement? Je suis dispo ce soir!",
        score: 5,
        time_ago: "il y a 3min",
        parent_id: nil,
        user: %{username: "player2"},
        replies: [
          %{
            id: 2,
            body: "Vers 20h30-21h normalement, ça te va?",
            score: 2,
            time_ago: "il y a 2min",
            parent_id: 1,
            user: %{username: "player1"}
          }
        ]
      },
      %{
        id: 3,
        body: "T'acceptes Platine 1 ou faut être Plat 2 minimum?",
        score: 3,
        time_ago: "il y a 1min",
        parent_id: nil,
        user: %{username: "player3"},
        replies: []
      }
    ]

    html = EEx.eval_file("lib/my_app/templates/show_post.html.eex",
      assigns: %{
        game: game,
        post: post,
        comments: comments,
        current_user: nil,
        all_games: []
      }
    )

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end


# ============================================================================
# FORMULAIRE CRÉATION POST (affiche toujours, disable si pas connecté)
# ============================================================================

get "/:slug/submit" do
  current_user = conn.assigns[:current_user]
  slug = conn.params["slug"]

  case GameCatalogService.get_by_slug(slug) do
    nil ->
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(404, "<h1>Game not found</h1>")

    game ->
      ranks = ["Fer", "Bronze", "Argent", "Or", "Platine", "Diamant", "Ascendant", "Immortel", "Radiant"]
      regions = ["Any", "EU", "NA", "SA", "ASIA"]

      html = EEx.eval_file("lib/my_app/templates/create_post.html.eex",
        assigns: %{
          game: game,
          ranks: ranks,
          regions: regions,
          form_data: %{},
          error_msg: nil,
          current_user: current_user  # Peut être nil
        }
      )

      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
  end
end

  # ============================================================================
  # CRÉATION POST (PROTÉGÉ)
  # ============================================================================

  post "/:slug/posts" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      slug = conn.params["slug"]
      params = conn.params

      case Validator.validate(params, %{
        type: ["required", "string"],
        description: ["required", "string", {:min, 10}, {:max, 500}]
      }) do
        {:ok, _} ->
          validated_params = case params["type"] do
            # Types "Cherche Joueurs"
            type when type in ["lf1", "lf2", "lf3", "lfg"] ->
              %{
                "type" => type,
                "game" => slug,
                "rank" => params["rank"],
                "region" => params["region"],
                "contact" => params["contact"],
                "description" => params["description"],
                "tags" => params["tags"],           # ← AJOUTE ICI
                "user_id" => current_user.id
              }

            # Types "Autre"
            type when type in ["strat", "clip"] ->
              %{
                "type" => type,
                "game" => slug,
                "url" => params["url"],
                "description" => params["description"],
                "tags" => params["tags"],           # ← AJOUTE ICI
                "user_id" => current_user.id
              }

            _unknown_type ->
              nil
          end

          cond do
            is_nil(validated_params) ->
              conn
              |> put_resp_header("location", "/g/#{slug}/submit")
              |> send_resp(302, "")

            true ->
              case PostService.create(validated_params) do
                {:ok, _post} ->
                  conn
                  |> put_resp_header("location", "/g/#{slug}")
                  |> send_resp(302, "")

                {:error, changeset} ->
                  IO.inspect(changeset, label: "❌ POST CREATE ERROR (DB/Changeset)")
                  conn
                  |> put_resp_header("location", "/g/#{slug}/submit")
                  |> send_resp(302, "")
              end
          end

        {:error, _validation_errors} ->
          conn
          |> put_resp_header("location", "/g/#{slug}/submit")
          |> send_resp(302, "")
      end
    end
  end
  # ============================================================================
  # UPVOTE POST (PUBLIC pour MVP)
  # ============================================================================

  # Dans GameFeedController, remplace la route upvote:

 post "/:slug/posts/:id/upvote" do
  current_user = conn.assigns[:current_user]

  unless current_user do
    conn
    |> put_resp_header("location", "/auth/login")
    |> send_resp(302, "")
  else
    slug = conn.params["slug"]
    post_id = String.to_integer(conn.params["id"])

    # Détecte d'où vient la requête
    redirect_to = conn.params["redirect_to"]

    case MyApp.Services.VoteService.toggle_vote(current_user.id, "post", post_id) do
      {:ok, _} ->
        # Redirige selon la source
        location = case redirect_to do
          "post_detail" -> "/g/#{slug}/posts/#{post_id}"  # Reste sur le post
          _ -> "/g/#{slug}"  # Retour au feed
        end

        conn
        |> put_resp_header("location", location)
        |> send_resp(302, "")

      {:error, _} ->
        conn
        |> send_resp(500, "Error")
    end
  end
end


  # ============================================================================
# UPVOTE COMMENTAIRE (PROTÉGÉ)
# ============================================================================

  post "/:slug/posts/:id/comments/:cid/upvote" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      slug = conn.params["slug"]
      post_id = conn.params["id"]
      comment_id = String.to_integer(conn.params["cid"])

      # Toggle le vote
      case MyApp.Services.VoteService.toggle_vote(current_user.id, "comment", comment_id) do
        {:ok, _} ->
          # Redirige vers le post
          conn
          |> put_resp_header("location", "/g/#{slug}/posts/#{post_id}")
          |> send_resp(302, "")

        {:error, _} ->
          conn
          |> send_resp(500, "Error")
      end
    end
  end

  # ============================================================================
  # SUPPRIMER POST (PROTÉGÉ + ownership)
  # ============================================================================

  post "/:slug/posts/:id/delete" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      slug = conn.params["slug"]
      post_id = String.to_integer(conn.params["id"])
      post = PostService.get(post_id)

      if Policy.can_delete_post?(current_user, post) do
        case PostService.delete(post_id, current_user.id) do
          {:ok, _} ->
            conn
            |> put_resp_header("location", "/g/#{slug}")
            |> send_resp(302, "")

          {:error, _} ->
            conn
            |> send_resp(403, "Erreur lors de la suppression")
        end
      else
        conn
        |> send_resp(403, "Non autorisé - ce n'est pas votre post")
      end
    end
  end

  # ============================================================================
  # PAGE DÉTAIL POST (PUBLIC)
  # ============================================================================

  get "/:slug/posts/:id" do
    slug = conn.params["slug"]
    post_id = String.to_integer(conn.params["id"])
    current_user = conn.assigns[:current_user]

    case GameCatalogService.get_by_slug(slug) do
      nil ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "<h1>Game not found</h1>")

      game ->
        post = PostService.get(post_id)

        if !post || post.game != slug do
          conn
          |> put_resp_content_type("text/html")
          |> send_resp(404, "<h1>Post not found</h1>")
        else
          comments = CommentService.list_by_post(post_id)

          html = EEx.eval_file("lib/my_app/templates/show_post.html.eex",
            assigns: %{
              game: game,
              post: PostService.decode_tags(post) |> PostService.add_time_ago(),
              comments: comments,
              current_user: current_user,
              all_games: GameCatalogService.all()
            }
          )

          conn
          |> put_resp_content_type("text/html")
          |> send_resp(200, html)
        end
    end
  end

  # ============================================================================
  # CRÉER COMMENTAIRE (PROTÉGÉ)
  # ============================================================================

  post "/:slug/posts/:id/comments" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      slug = conn.params["slug"]
      post_id = String.to_integer(conn.params["id"])
      params = conn.params

      comment_params = %{
        "body" => params["body"],
        "user_id" => current_user.id,
        "post_id" => post_id,
        "parent_id" => params["parent_id"]
      }

      case CommentService.create(comment_params) do
        {:ok, _comment} ->
          conn
          |> put_resp_header("location", "/g/#{slug}/posts/#{post_id}")
          |> send_resp(302, "")

        {:error, _changeset} ->
          conn
          |> put_resp_header("location", "/g/#{slug}/posts/#{post_id}")
          |> send_resp(302, "")
      end
    end
  end

  # ============================================================================
  # SUPPRIMER COMMENTAIRE (PROTÉGÉ + ownership)
  # ============================================================================

  post "/:slug/posts/:id/comments/:cid/delete" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      slug = conn.params["slug"]
      post_id = conn.params["id"]
      comment_id = String.to_integer(conn.params["cid"])

      comment = CommentService.get(comment_id)

      if Policy.can_delete_comment?(current_user, comment) do
        case CommentService.delete(comment_id) do
          {:ok, _} ->
            conn
            |> put_resp_header("location", "/g/#{slug}/posts/#{post_id}")
            |> send_resp(302, "")

          {:error, _} ->
            conn
            |> send_resp(403, "Erreur")
        end
      else
        conn
        |> send_resp(403, "Non autorisé")
      end
    end
  end

  # ============================================================================
  # FEED DU JEU (EN DERNIER - route générique)
  # ============================================================================

  get "/:slug" do
    slug = conn.params["slug"]
    current_user = conn.assigns[:current_user]

    case GameCatalogService.get_by_slug(slug) do
      nil ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "<h1>Game not found</h1>")

      game ->
        posts = PostService.list_active(slug)
        |> Enum.map(&MyApp.Schemas.Post.decode_tags/1)  # ← AJOUTE CETTE LIGNE

        stats = GameCatalogService.get_stats(slug)

        html = EEx.eval_file("lib/my_app/templates/game_feed.html.eex",
          assigns: %{
            game: game,
            posts: posts,
            stats: stats,
            current_user: current_user,
            all_games: GameCatalogService.all()
          }
        )

        conn
        |> put_resp_content_type("text/html")
        |> send_resp(200, html)
    end
  end
end
