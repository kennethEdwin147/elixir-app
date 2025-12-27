ExUnit.start()

# Start Ecto Sandbox for test isolation
Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, :manual)
