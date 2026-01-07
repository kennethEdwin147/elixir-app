defmodule MyApp.Workers.CleanupWorker do
  use GenServer
  alias MyApp.Contexts.User

  # On définit l'intervalle (ex: toutes les heures)
  @interval 60 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Planifie le premier nettoyage
    schedule_cleanup()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    # Exécute le nettoyage
    User.delete_expired_tokens()

    # Re-planifie pour dans une heure
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    # Envoie le message :work à soi-même après @interval
    Process.send_after(self(), :work, @interval)
  end
end
