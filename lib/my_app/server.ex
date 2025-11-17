defmodule MyApp.Server do
  def start do
    Plug.Cowboy.http(MyApp.Router, [], port: 4000)
  end
end
