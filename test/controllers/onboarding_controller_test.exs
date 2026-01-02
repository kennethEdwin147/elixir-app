defmodule MyApp.Controllers.OnboardingControllerTest do
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
  # TESTS GET /onboarding
  # ============================================================================

  test "GET /onboarding shows form if not completed" do
    # Crée user sans onboarding
    {:ok, user} = UserService.create_user(%{
      "email" => "newuser@test.com",
      "password" => "password123"
    })

    conn = conn(:get, "/onboarding")
    |> init_test_session(%{user_id: user.id})
    |> Router.call(@opts)

    assert conn.status == 200
    assert conn.resp_body =~ "Complète ton profil"
    assert conn.resp_body =~ "username"
    assert conn.resp_body =~ "newuser"  # Suggested username
  end

  test "GET /onboarding redirects to dashboard if already completed" do
    # Crée user avec onboarding complété
    {:ok, user} = UserService.create_user(%{
      "email" => "completed@test.com",
      "password" => "password123"
    })

    {:ok, _} = UserService.complete_onboarding(user.id, %{
      "username" => "completed_user",
      "display_name" => "Completed User"
    })

    conn = conn(:get, "/onboarding")
    |> init_test_session(%{user_id: user.id})
    |> Router.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/dashboard"]
  end

  test "GET /onboarding redirects to register if not logged in" do
    conn = conn(:get, "/onboarding")
    |> init_test_session(%{})
    |> Router.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/register"]
  end

  # ============================================================================
  # TESTS POST /onboarding - SUCCESS
  # ============================================================================

  test "POST /onboarding completes onboarding with valid data" do
    # Crée user
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "test_user",
      "display_name" => "Test User"
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    # Vérifie redirect
    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/dashboard"]

    # Vérifie DB
    updated_user = Repo.get(User, user.id)
    assert updated_user.username == "test_user"
    assert updated_user.display_name == "Test User"
    assert updated_user.onboarding_completed == true
  end

  test "POST /onboarding with display_name saves both fields" do
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "ken_mtl",
      "display_name" => "Ken | Jett Main ⚡"
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 302

    updated_user = Repo.get(User, user.id)
    assert updated_user.username == "ken_mtl"
    assert updated_user.display_name == "Ken | Jett Main ⚡"
    assert updated_user.onboarding_completed == true
  end

  test "POST /onboarding allows duplicate usernames" do
    # Crée premier user avec username
    {:ok, user1} = UserService.create_user(%{
      "email" => "user1@test.com",
      "password" => "password123"
    })
    UserService.complete_onboarding(user1.id, %{
      "username" => "duplicate_name",
      "display_name" => "User One"
    })

    # Crée deuxième user
    {:ok, user2} = UserService.create_user(%{
      "email" => "user2@test.com",
      "password" => "password123"
    })

    # Utilise même username (devrait marcher, pas de unique constraint)
    conn = conn(:post, "/onboarding", %{
      "username" => "duplicate_name",
      "display_name" => "User Two"
    })
    |> init_test_session(%{user_id: user2.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 302  # Success!

    user2_updated = Repo.get(User, user2.id)
    assert user2_updated.username == "duplicate_name"
  end

  # ============================================================================
  # TESTS POST /onboarding - VALIDATION ERRORS
  # ============================================================================

  test "POST /onboarding fails with username too short" do
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "ab",  # Seulement 2 chars
      "display_name" => "Test User"
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "username"

    # Vérifie que onboarding pas complété
    user_unchanged = Repo.get(User, user.id)
    assert user_unchanged.onboarding_completed == false
  end

  test "POST /onboarding fails with username too long" do
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "this_username_is_way_too_long_for_validation",  # > 20 chars
      "display_name" => "Test User"
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "username"
  end

  test "POST /onboarding fails with invalid characters in username" do
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "user@name!",  # Caractères invalides
      "display_name" => "Test User"
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "only letters, numbers, underscore and dash" ||
           conn.resp_body =~ "format"
  end

  test "POST /onboarding fails with empty username" do
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "",
      "display_name" => "Test User"
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "can't be blank" ||
           conn.resp_body =~ "required"
  end

  test "POST /onboarding fails with empty display_name" do
    {:ok, user} = UserService.create_user(%{
      "email" => "test@test.com",
      "password" => "password123"
    })

    conn = conn(:post, "/onboarding", %{
      "username" => "test_user",
      "display_name" => ""  # Vide
    })
    |> init_test_session(%{user_id: user.id})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 400
    assert conn.resp_body =~ "can't be blank" ||
           conn.resp_body =~ "required"

    # Vérifie que onboarding pas complété
    user_unchanged = Repo.get(User, user.id)
    assert user_unchanged.onboarding_completed == false
  end

  # ============================================================================
  # TESTS POST /onboarding - AUTHENTICATION
  # ============================================================================

  test "POST /onboarding redirects to register if not logged in" do
    conn = conn(:post, "/onboarding", %{
      "username" => "test_user",
      "display_name" => "Test User"
    })
    |> init_test_session(%{})
    |> put_req_header("content-type", "application/x-www-form-urlencoded")
    |> Router.call(@opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/auth/register"]
  end
end
