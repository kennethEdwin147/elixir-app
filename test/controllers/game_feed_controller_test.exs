defmodule MyApp.Controllers.GameFeedControllerTest do
  use ExUnit.Case, async: false  # ← CHANGE: async: false
  import Plug.Test               # ← CHANGE: import au lieu de use
  import Plug.Conn               # ← ADD

  alias MyApp.Router
  alias MyApp.Repo
  alias MyApp.Schemas.{User, Post}

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
    description: "Looking for teammates to play ranked",
    contact: "Discord: test#1234",
    tags: Jason.encode!(["ranked", "mic", "chill"]),
    user_id: user.id,
    score: 0,
    active: true
  })

  %{user: user, post: post}
end

  # ============================================================================
  # GET /g/:slug - Game Feed
  # ============================================================================

  test "GET /g/valorant shows game feed" do
    conn = conn(:get, "/g/valorant")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ "ValoLFG"
    assert conn.resp_body =~ "nouveau"
    assert conn.resp_body =~ "populaire"
  end

  test "GET /g/valorant shows posts", %{post: post} do
    conn = conn(:get, "/g/valorant")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ post.description
  end

  test "GET /g/valorant shows tags in posts", %{post: _post} do
    conn = conn(:get, "/g/valorant")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ "ranked"
    assert conn.resp_body =~ "mic"
  end

  test "GET /g/invalid returns 404" do
    conn = conn(:get, "/g/invalidgame")
    conn = Router.call(conn, @opts)

    assert conn.status == 404
    assert conn.resp_body =~ "Game not found"
  end

  # ============================================================================
  # GET /g/:slug/submit - Submit Form
  # ============================================================================

  test "GET /g/valorant/submit shows form when logged in", %{user: user} do
    conn = conn(:get, "/g/valorant/submit")
    |> init_test_session(%{user_id: user.id})  # ← FIX
    |> put_session(:user_id, user.id)
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Mon Post"
    assert conn.resp_body =~ "Type de post"
  end

  test "GET /g/valorant/submit shows form when NOT logged in" do
    conn = conn(:get, "/g/valorant/submit")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Mon Post"
  end

  test "GET /g/invalid/submit returns 404" do
    conn = conn(:get, "/g/invalidgame/submit")
    conn = Router.call(conn, @opts)

    assert conn.status == 404
  end

  # ============================================================================
  # GET /g/:slug/posts/:id - Post Detail
  # ============================================================================

  test "GET /g/valorant/posts/:id shows post detail", %{post: post} do
    conn = conn(:get, "/g/valorant/posts/#{post.id}")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ post.description
    assert conn.resp_body =~ "commentaire"
  end

  test "GET /g/valorant/posts/:id shows tags", %{post: post} do
    conn = conn(:get, "/g/valorant/posts/#{post.id}")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
    assert conn.resp_body =~ "ranked"
    assert conn.resp_body =~ "mic"
    assert conn.resp_body =~ "chill"
  end

  test "GET /g/valorant/posts/999 returns 404" do
    conn = conn(:get, "/g/valorant/posts/999")
    conn = Router.call(conn, @opts)

    assert conn.status == 404
  end

  test "GET /g/valorant/posts/:id with wrong game returns 404", %{user: user} do
    # Create post for different game
    {:ok, other_post} = Repo.insert(%Post{
      type: "lfg",
      game: "csgo",
      description: "CS:GO LFG",
      user_id: user.id,
      score: 0,
      active: true
    })

    conn = conn(:get, "/g/valorant/posts/#{other_post.id}")
    conn = Router.call(conn, @opts)

    assert conn.status == 404
  end
end
