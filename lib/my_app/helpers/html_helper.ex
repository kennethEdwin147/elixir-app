defmodule MyApp.Helpers.HtmlHelper do
  @moduledoc """
  Helper pour échapper le HTML et prévenir les attaques XSS.
  """

  @doc """
  Échappe les caractères HTML dangereux.
  Convertit: < > & " ' en entités HTML sécurisées.
  """
  def escape(nil), do: ""

  def escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")   # Doit être en premier
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  def escape(other), do: to_string(other) |> escape()
end
