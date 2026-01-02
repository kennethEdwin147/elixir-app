defmodule MyApp.Controllers.GameFeedControllerVotesTest do
  use ExUnit.Case, async: false  # ← CHANGE: async: false
  import Plug.Test               # ← CHANGE: import au lieu de use
  import Plug.Conn               # ← ADD

  alias MyApp.Router
  alias MyApp.Repo
  alias MyApp.Schemas.{User, Post, Comment, Vote}
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
    description: "Looking for teammates",
    user_id: user.id,
    score: 0,
    active: true
  })

  %{user: user, post: post}
end

  # ============================================================================
  # POST /g/:slug/posts/:id/upvote - Upvote Post
  # ============================================================================

  test "POST /g/valorant/posts/:id/upvote creates vote", %{user: user, post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant"]

    # Verify vote was created
    vote = Repo.one(from v in Vote,
      where: v.user_id == ^user.id and v.votable_id == ^post.id and v.votable_type == "post")
    assert vote != nil
  end

  test "POST post upvote toggles vote (removes if exists)", %{user: user, post: post} do
    # Create initial vote
    {:ok, _vote} = Repo.insert(%Vote{
      user_id: user.id,
      votable_id: post.id,
      votable_type: "post"
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    # Verify vote was removed
    vote = Repo.one(from v in Vote,
      where: v.user_id == ^user.id and v.votable_id == ^post.id and v.votable_type == "post")
    assert vote == nil
  end

  test "POST post upvote redirects to post detail when redirect_to=post_detail", %{user: user, post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/upvote", %{"redirect_to" => "post_detail"})
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/posts/#{post.id}"]
  end

  test "POST post upvote redirects to feed by default", %{user: user, post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant"]
  end

  test "POST post upvote redirects to login when not logged in", %{post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/login"]
  end

  test "POST post upvote twice removes vote", %{user: user, post: post} do
    # First upvote
    conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> Router.call(@opts)

    # Second upvote (toggle)
    conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> Router.call(@opts)

    # Verify no vote exists
    vote = Repo.one(from v in Vote,
      where: v.user_id == ^user.id and v.votable_id == ^post.id and v.votable_type == "post")
    assert vote == nil
  end

  # ============================================================================
  # POST /g/:slug/posts/:id/comments/:cid/upvote - Upvote Comment
  # ============================================================================

  test "POST comment upvote creates vote", %{user: user, post: post} do
    # Create comment first
    {:ok, comment} = Repo.insert(%Comment{
      body: "Test comment for upvote",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/posts/#{post.id}"]

    # Verify vote was created
    vote = Repo.one(from v in Vote,
      where: v.user_id == ^user.id and v.votable_id == ^comment.id and v.votable_type == "comment")
    assert vote != nil
  end

  test "POST comment upvote toggles vote", %{user: user, post: post} do
    {:ok, comment} = Repo.insert(%Comment{
      body: "Test comment",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    # Create initial vote
    {:ok, _vote} = Repo.insert(%Vote{
      user_id: user.id,
      votable_id: comment.id,
      votable_type: "comment"
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    # Verify vote was removed
    vote = Repo.one(from v in Vote,
      where: v.user_id == ^user.id and v.votable_id == ^comment.id and v.votable_type == "comment")
    assert vote == nil
  end

  test "POST comment upvote redirects to post detail", %{user: user, post: post} do
    {:ok, comment} = Repo.insert(%Comment{
      body: "Test",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/posts/#{post.id}"]
  end

  test "POST comment upvote redirects to login when not logged in", %{user: user, post: post} do
    {:ok, comment} = Repo.insert(%Comment{
      body: "Test",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/upvote")
    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/login"]
  end

  test "POST comment upvote twice removes vote", %{user: user, post: post} do
    {:ok, comment} = Repo.insert(%Comment{
      body: "Test",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    # First upvote
    conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> Router.call(@opts)

    # Second upvote (toggle)
    conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> Router.call(@opts)

    # Verify no vote exists
    vote = Repo.one(from v in Vote,
      where: v.user_id == ^user.id and v.votable_id == ^comment.id and v.votable_type == "comment")
    assert vote == nil
  end

  test "Different users can upvote same post", %{user: user, post: post} do
    # Create second user
    {:ok, user2} = Repo.insert(%User{
      email: "user2@example.com",
      username: "user2",
      display_name: "User 2",
      password_hash: Bcrypt.hash_pwd_salt("password"),
      onboarding_completed: true
    })

    # User 1 upvotes
    conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> Router.call(@opts)

    # User 2 upvotes
    conn(:post, "/g/valorant/posts/#{post.id}/upvote")
    |> init_test_session(%{user_id: user2.id})
    |> fetch_session()
    |> Router.call(@opts)

    # Verify both votes exist
    votes = Repo.all(from v in Vote, where: v.votable_id == ^post.id and v.votable_type == "post")
    assert length(votes) == 2
  end
end
