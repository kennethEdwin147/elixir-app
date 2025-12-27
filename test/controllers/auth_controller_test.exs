defmodule MyApp.Controllers.AuthControllerTest do
  use ExUnit.Case
  import Plug.Test
  import Plug.Conn

  alias MyApp.{Router, Repo}
  alias MyApp.Schemas.User
  alias MyApp.Services.UserService

  @opts Router.init([])

  # Setup: Rollback DB après chaque test
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ============================================================================
  # TESTS PAGES (GET)
  # ============================================================================

  test "GET /auth/login returns login form" do
    conn = conn(:get, "/auth/login")
    |> Router.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Email"
  end

  test "GET /auth/register returns register form" do
    conn = conn(:get, "/auth/register")
    |> Router.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Email"
  end

  # ============================================================================
  # TESTS REGISTRATION
  # ============================================================================

  test "successful registration creates user and redirects" do
    conn = conn(:post, "/auth/register", %{
      "email" => "newuser@test.com",
      "password" => "password123",
      "password_confirm" => "password123"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    # Vérifie redirect
    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant"]

    # Vérifie user créé en DB
    user = Repo.get_by(User, email: "newuser@test.com")
    assert user != nil
    assert user.username == "newuser"

    # Vérifie session créée
    assert get_session(conn, :user_id) == user.id
  end

  test "registration with existing email fails" do
    # Crée user d'abord
    UserService.create_user(%{
      "email" => "existing@test.com",
      "username" => "existing",
      "password" => "password123"
    })

    # Essaie de re-register
    conn = conn(:post, "/auth/register", %{
      "email" => "existing@test.com",
      "password" => "password123",
      "password_confirm" => "password123"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "déjà utilisé"
  end

  test "registration with mismatched passwords fails" do
    conn = conn(:post, "/auth/register", %{
      "email" => "test@test.com",
      "password" => "password123",
      "password_confirm" => "different"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400

    # Vérifie que user PAS créé
    user = Repo.get_by(User, email: "test@test.com")
    assert user == nil
  end

  test "registration with short password fails" do
    conn = conn(:post, "/auth/register", %{
      "email" => "test@test.com",
      "password" => "123",
      "password_confirm" => "123"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
  end

  # ============================================================================
  # TESTS LOGIN
  # ============================================================================

  test "login with correct credentials succeeds" do
    # Crée user
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "username" => "test",
      "password" => "password123"
    })

    # Login
    conn = conn(:post, "/auth/login", %{
      "email" => "test@test.com",
      "password" => "password123"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/g/valorant"]
    assert get_session(conn, :user_id) == user.id
    assert get_session(conn, :user_email) == user.email
  end

  test "login with wrong password fails" do
    # Crée user
    UserService.create_user(%{
      "email" => "test@test.com",
      "username" => "test",
      "password" => "password123"
    })

    # Login avec mauvais password
    conn = conn(:post, "/auth/login", %{
      "email" => "test@test.com",
      "password" => "wrongpassword"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "incorrect"
  end

  test "login with non-existent email fails" do
    conn = conn(:post, "/auth/login", %{
      "email" => "nonexistent@test.com",
      "password" => "password123"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "incorrect"
  end

  # ============================================================================
  # TESTS LOGOUT
  # ============================================================================

  test "logout destroys session and redirects" do
    # Crée session
    conn = conn(:get, "/auth/logout")
    |> init_test_session(%{user_id: 123, user_email: "test@test.com"})
    |> Router.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/login"]
  end
end
