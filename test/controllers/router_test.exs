defmodule MyApp.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Plug.Conn

  alias MyApp.Router

  @opts Router.init([])

  test "GET / returns 200" do
    conn = conn(:get, "/")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
  end

  test "GET /login returns 200" do
    conn = conn(:get, "/login")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
  end

  test "GET /register returns 200" do
    conn = conn(:get, "/register")
    conn = Router.call(conn, @opts)

    assert conn.status == 200
  end

  test "GET /dashboard redirects to login when not authenticated" do
    conn = conn(:get, "/dashboard")
    conn = Router.call(conn, @opts)

    assert conn.status == 302
    assert get_resp_header(conn, "location") == ["/login"]
  end

  test "GET /nonexistent returns 404" do
    conn = conn(:get, "/nonexistent")
    conn = Router.call(conn, @opts)

    assert conn.status == 404
  end
end
