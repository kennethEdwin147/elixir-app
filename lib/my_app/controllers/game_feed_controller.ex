
defmodule MyApp.Controllers.GameFeedController do
  use Plug.Router
  require EEx

  alias MyApp.Services.{PostService, GameCatalogService, CommentService}

  plug :match
  plug :dispatch

  # Routes:
  # GET  /g/:slug              → Feed du jeu
  # GET  /g/:slug/posts/:id    → Détail post + commentaires
  # POST /g/:slug/posts/:id/comments → Créer commentaire

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
        user_id: 1,  # Connecté pour tester les formulaires
        all_games: []
      }
    )

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end



  # ============================================================================
  # PAGE DÉTAIL POST
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
  # CRÉER COMMENTAIRE
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
