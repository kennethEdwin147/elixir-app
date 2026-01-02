# test/my_app/controllers/game_feed_controller_posts_test.exs

defmodule MyApp.Controllers.GameFeedControllerPostsTest do
  use ExUnit.Case, async: false  # ← CHANGE: async: false
  import Plug.Test               # ← CHANGE: import au lieu de use
  import Plug.Conn               # ← ADD

  alias MyApp.Router
  alias MyApp.Repo
  alias MyApp.Schemas.{User, Post}
  import Ecto.Query

  @opts Router.init([])

 setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)

  # Create test user
  {:ok, user} = Repo.insert(%User{
    email: "test@example.com",
    username: "testuser",
    display_name: "Test User",
    password_hash: Bcrypt.hash_pwd_salt("password123"),
    onboarding_completed: true
  })

  # Create test post
  {:ok, post} = Repo.insert(%Post{
    type: "lfg",
    game: "valorant",
    rank: "Platine",
    region: "EU",
    description: "Looking for teammates",
    contact: "Discord: test#1234",
    user_id: user.id,
    score: 0,
    active: true
  })

  %{user: user, post: post}
end

  # ============================================================================
  # POST /g/:slug/posts - Create Post
  # ============================================================================

  test "POST /g/valorant/posts creates LFG post when logged in", %{user: user} do
    conn = conn(:post, "/g/valorant/posts", %{
      "type" => "lf2",
      "rank" => "Diamant",
      "region" => "EU",
      "contact" => "Discord: newuser#1234",
      "description" => "Looking for duo to climb ranked together",
      "tags" => "ranked, mic, competitive"
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant"]

    # Verify post was created
    post = Repo.one(from p in Post, where: p.description == "Looking for duo to climb ranked together")
    assert post != nil
    assert post.type == "lf2"
    assert post.rank == "Diamant"
    assert post.region == "EU"
  end

  test "POST /g/valorant/posts creates STRAT post", %{user: user} do
    conn = conn(:post, "/g/valorant/posts", %{
      "type" => "strat",
      "url" => "https://youtube.com/watch?v=123",
      "description" => "New Jett boost on Ascent very useful",
      "tags" => "jett, ascent, boost"
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    post = Repo.one(from p in Post, where: p.type == "strat")
    assert post != nil
    assert post.url == "https://youtube.com/watch?v=123"
  end

  test "POST /g/valorant/posts creates CLIP post", %{user: user} do
    conn = conn(:post, "/g/valorant/posts", %{
      "type" => "clip",
      "url" => "https://youtube.com/watch?v=456",
      "description" => "Insane ace clutch on Haven last round",
      "tags" => "ace, clutch, haven"
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    post = Repo.one(from p in Post, where: p.type == "clip")
    assert post != nil
    assert post.url == "https://youtube.com/watch?v=456"
  end

  test "POST /g/valorant/posts saves tags correctly", %{user: user} do
    conn = conn(:post, "/g/valorant/posts", %{
      "type" => "lf2",
      "rank" => "Gold",
      "region" => "NA",
      "contact" => "test",
      "description" => "LFG ranked with mic only please",
      "tags" => "ranked, mic, chill, duelist"
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    post = Repo.one(from p in Post, where: p.rank == "Gold")
    assert post != nil

    {:ok, tags} = Jason.decode(post.tags)
    assert "ranked" in tags
    assert "mic" in tags
    assert "chill" in tags
    assert "duelist" in tags
  end

  test "POST /g/valorant/posts redirects to login when not logged in" do
    conn = conn(:post, "/g/valorant/posts", %{
      "type" => "lf2",
      "description" => "Test post"
    })
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/login"]
  end

  test "POST /g/valorant/posts fails with short description", %{user: user} do
    conn = conn(:post, "/g/valorant/posts", %{
      "type" => "lf2",
      "rank" => "Gold",
      "region" => "EU",
      "contact" => "test",
      "description" => "Short"  # Too short (< 10 chars)
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/submit"]
  end

  test "POST /g/valorant/posts fails with missing type", %{user: user} do
    conn = conn(:post, "/g/valorant/posts", %{
      "description" => "Missing type field here"
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/submit"]
  end

  # ============================================================================
  # POST /g/:slug/posts/:id/delete - Delete Post
  # ============================================================================

  test "POST /g/valorant/posts/:id/delete soft-deletes own post", %{user: user, post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/delete")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant"]

    # Verify post was soft-deleted
    deleted_post = Post |> where(id: ^post.id) |> Repo.one()
    assert deleted_post.active == false
  end

  test "POST delete fails when not post owner", %{post: post} do
    # Create different user
    {:ok, other_user} = Repo.insert(%User{
      email: "other@example.com",
      username: "otheruser",
      display_name: "Other",
      password_hash: Bcrypt.hash_pwd_salt("password"),
      onboarding_completed: true
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/delete")
    |> init_test_session(%{user_id: other_user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 403
    assert conn.resp_body =~ "Non autorisé"

    # Verify post still active
    unchanged_post = Repo.get(Post, post.id)
    assert unchanged_post.active == true
  end

  test "POST delete redirects to login when not logged in", %{post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/delete")
    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/login"]
  end
end
