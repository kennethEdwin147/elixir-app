defmodule MyApp.Controllers.GameFeedControllerCommentsTest do
   use ExUnit.Case, async: false  # ← CHANGE: async: false
  import Plug.Test               # ← CHANGE: import au lieu de use
  import Plug.Conn               # ← ADD

  alias MyApp.Router
  alias MyApp.Repo
  alias MyApp.Schemas.{User, Post, Comment}
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
  # POST /g/:slug/posts/:id/comments - Create Comment
  # ============================================================================

  test "POST /g/valorant/posts/:id/comments creates comment", %{user: user, post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments", %{
      "body" => "Great post! I'm interested in playing",
      "parent_id" => nil
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/posts/#{post.id}"]

    # Verify comment was created
    comment = Repo.one(from c in Comment, where: c.post_id == ^post.id)
    assert comment != nil
    assert comment.body == "Great post! I'm interested in playing"
    assert comment.user_id == user.id
  end

  test "POST comment creates reply when parent_id set", %{user: user, post: post} do
    # Create parent comment
    {:ok, parent} = Repo.insert(%Comment{
      body: "Parent comment",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments", %{
      "body" => "This is a reply to parent",
      "parent_id" => to_string(parent.id)
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    # Verify reply was created
    reply = Repo.one(from c in Comment, where: c.parent_id == ^parent.id)
    assert reply != nil
    assert reply.body == "This is a reply to parent"
  end

  test "POST comment with empty body redirects back", %{user: user, post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments", %{
      "body" => "",
      "parent_id" => nil
    })
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/posts/#{post.id}"]

    # Verify no comment was created
    count = Repo.one(from c in Comment, select: count(c.id))
    assert count == 0
  end

  test "POST comment redirects to login when not logged in", %{post: post} do
    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments", %{
      "body" => "Test comment"
    })
    |> put_req_header("content-type", "application/x-www-form-urlencoded")

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/login"]
  end

  # ============================================================================
  # POST /g/:slug/posts/:id/comments/:cid/delete - Delete Comment
  # ============================================================================

  test "POST comment delete removes own comment", %{user: user, post: post} do
    {:ok, comment} = Repo.insert(%Comment{
      body: "Comment to delete",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/delete")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant/posts/#{post.id}"]

    # Verify comment was deleted
    assert Repo.get(Comment, comment.id) == nil
  end

  test "POST comment delete also deletes replies", %{user: user, post: post} do
    # Create parent comment
    {:ok, parent} = Repo.insert(%Comment{
      body: "Parent comment",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    # Create reply
    {:ok, reply} = Repo.insert(%Comment{
      body: "Reply to parent",
      user_id: user.id,
      post_id: post.id,
      parent_id: parent.id,
      score: 0
    })

    # Delete parent
    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{parent.id}/delete")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 302

    # Verify both parent and reply were deleted
    assert Repo.get(Comment, parent.id) == nil
    assert Repo.get(Comment, reply.id) == nil
  end

  test "POST comment delete fails when not owner", %{user: user, post: post} do
    # Create different user
    {:ok, other_user} = Repo.insert(%User{
      email: "other@example.com",
      username: "otheruser",
      display_name: "Other",
      password_hash: Bcrypt.hash_pwd_salt("password"),
      onboarding_completed: true
    })

    # Comment by other user
    {:ok, comment} = Repo.insert(%Comment{
      body: "Other's comment",
      user_id: other_user.id,
      post_id: post.id,
      score: 0
    })

    # Try to delete with original user
    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/delete")
    |> init_test_session(%{user_id: user.id})
    |> fetch_session()

    conn = Router.call(conn, @opts)

    assert conn.status == 403
    assert conn.resp_body =~ "Non autorisé"

    # Verify comment still exists
    assert Repo.get(Comment, comment.id) != nil
  end

  test "POST comment delete redirects to login when not logged in", %{user: user, post: post} do
    {:ok, comment} = Repo.insert(%Comment{
      body: "Test comment",
      user_id: user.id,
      post_id: post.id,
      score: 0
    })

    conn = conn(:post, "/g/valorant/posts/#{post.id}/comments/#{comment.id}/delete")
    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/login"]
  end
end
