defmodule MyApp.Views.ConnectionsView do
  @moduledoc """
  View helpers pour ConnectionController.
  """

  @doc """
  Formate une date/datetime en format français.

  ## Exemples
      iex> format_date(~U[2025-01-07 10:00:00Z])
      "07/01/2025"
  """
  def format_date(datetime) when is_struct(datetime, DateTime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  def format_date(datetime) when is_struct(datetime, NaiveDateTime) do
    Calendar.strftime(datetime, "%d/%m/%Y")
  end

  def format_date(_), do: "Date inconnue"
end
