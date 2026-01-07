defmodule MyApp.Views.ProfileDiscoveryView do
  @moduledoc """
  View helpers pour ProfileDiscoveryController.
  Formatage et extraction de données des profils.
  """

  @doc """
  Récupère l'agent principal pour Valorant depuis game_specific_data.
  """
  def get_agent(profile) do
    case Enum.find(profile.game_specific_data, fn data -> data.key == "main_agent" end) do
      nil -> "Inconnu"
      data -> data.value
    end
  end

  @doc """
  Récupère la legend principale pour Apex depuis game_specific_data.
  """
  def get_legend(profile) do
    case Enum.find(profile.game_specific_data, fn data -> data.key == "main_legend" end) do
      nil -> "Inconnu"
      data -> data.value
    end
  end

  @doc """
  Récupère le champion principal pour LoL depuis game_specific_data.
  """
  def get_champion(profile) do
    case Enum.find(profile.game_specific_data, fn data -> data.key == "main_champion" end) do
      nil -> "Inconnu"
      data -> data.value
    end
  end

  @doc """
  Formate les disponibilités en texte lisible.

  ## Exemples
      iex> format_availabilities(availabilities)
      "Mar 19:00-23:00, Jeu 19:00-23:00"
  """
  def format_availabilities([]), do: "Non renseigné"

  def format_availabilities(availabilities) do
    availabilities
    |> Enum.map(fn avail ->
      day = day_name(avail.day_of_week)
      start_time = format_time(avail.start_time)
      end_time = format_time(avail.end_time)
      "#{day} #{start_time}-#{end_time}"
    end)
    |> Enum.join(", ")
  end

  # Formate un Time en format HH:MM
  defp format_time(%Time{} = time) do
    Time.to_string(time) |> String.slice(0..4)
  end

  # Noms de jours abrégés
  defp day_name(0), do: "Dim"
  defp day_name(1), do: "Lun"
  defp day_name(2), do: "Mar"
  defp day_name(3), do: "Mer"
  defp day_name(4), do: "Jeu"
  defp day_name(5), do: "Ven"
  defp day_name(6), do: "Sam"
  defp day_name(_), do: "?"
end
