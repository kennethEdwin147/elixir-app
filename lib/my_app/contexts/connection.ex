defmodule MyApp.Contexts.Connection do
  @moduledoc """
  Service pour gérer les demandes de connexion et les connexions établies.
  Flow: User A envoie une demande → User B accepte → Connection créée

  ## Demandes de connexion
  - send_request(attrs)                      # Envoyer demande
  - accept_request(id)                       # Accepter → crée Connection
  - decline_request(id)                      # Refuser
  - cancel_request(id)                       # Annuler (si pending)

  ## Lister demandes
  - list_received_requests(user_id, game_id, opts) # Demandes reçues
  - list_sent_requests(user_id, game_id, opts)     # Demandes envoyées
  - get_request(id)                          # Récupère une demande
  - request_exists?(req_id, target_id, game_id)  # Vérifier si existe

  ## Connexions établies
  - create_connection(user_a, user_b, game_id)   # Créer connexion
  - get_connection(user_a, user_b, game_id)      # Récupérer
  - has_connection?(user_a, user_b, game_id)     # Vérifier
  - list_connections(user_id, game_id)           # Toutes les connexions
  - delete_connection(user_a, user_b, game_id)   # Unfriend
  - increment_play_count(user_a, user_b, game_id) # +1 partie jouée

  ## Statistiques
  - count_connections(user_id, game_id)      # Nb connexions
  - count_pending_requests(user_id, game_id) # Nb demandes en attente
  """

  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Schemas.{ConnectionRequest, Connection}

  # ============================================================================
  # CONNECTION REQUESTS
  # ============================================================================

  @doc """
  Envoie une demande de connexion.

  ## Exemples
      iex> send_request(%{
        requester_id: "uuid-123",
        target_id: "uuid-456",
        game_id: "uuid-789",
        message: "Hey! Let's play together"
      })
      {:ok, %ConnectionRequest{}}

  ## Erreurs
    - {:error, :self_request} - tentative de demande à soi-même
    - {:error, :already_connected} - déjà connectés
    - {:error, :request_exists} - demande déjà envoyée
  """
  def send_request(attrs) do
    requester_id = attrs[:requester_id] || attrs["requester_id"]
    target_id = attrs[:target_id] || attrs["target_id"]
    game_id = attrs[:game_id] || attrs["game_id"]

    cond do
      requester_id == target_id ->
        {:error, :self_request}

      has_connection?(requester_id, target_id, game_id) ->
        {:error, :already_connected}

      request_exists?(requester_id, target_id, game_id) ->
        {:error, :request_exists}

      true ->
        %ConnectionRequest{}
        |> ConnectionRequest.changeset(attrs)
        |> Repo.insert()
    end
  end

  @doc """
  Accepte une demande de connexion.
  Crée automatiquement une Connection et met à jour le status à "accepted".
  """
  def accept_request(request_id) do
    case get_request(request_id) do
      nil ->
        {:error, :not_found}

      %ConnectionRequest{status: "accepted"} ->
        {:error, :already_accepted}

      %ConnectionRequest{status: "declined"} ->
        {:error, :already_declined}

      request ->
        Repo.transaction(fn ->
          # 1. Créer la connexion
          {:ok, connection} = create_connection(
            request.requester_id,
            request.target_id,
            request.game_id
          )

          # 2. Mettre à jour le status de la demande
          request
          |> ConnectionRequest.status_changeset("accepted")
          |> Repo.update!()

          connection
        end)
    end
  end

  @doc """
  Refuse une demande de connexion.
  """
  def decline_request(request_id) do
    case get_request(request_id) do
      nil ->
        {:error, :not_found}

      %ConnectionRequest{status: "accepted"} ->
        {:error, :already_accepted}

      request ->
        request
        |> ConnectionRequest.status_changeset("declined")
        |> Repo.update()
    end
  end

  @doc """
  Annule une demande envoyée (uniquement si status = "pending").
  """
  def cancel_request(request_id) do
    case get_request(request_id) do
      nil ->
        {:error, :not_found}

      %ConnectionRequest{status: status} when status != "pending" ->
        {:error, :cannot_cancel}

      request ->
        Repo.delete(request)
    end
  end

  @doc """
  Récupère une demande par ID.
  """
  def get_request(request_id) do
    ConnectionRequest
    |> where([r], r.id == ^request_id)
    |> preload([:requester, :target, :game])
    |> Repo.one()
  end

  @doc """
  Liste les demandes reçues par un user pour un jeu.

  Options:
    - status: "pending", "accepted", "declined" (défaut: "pending")
  """
  def list_received_requests(user_id, game_id, opts \\ []) do
    status = Keyword.get(opts, :status, "pending")

    ConnectionRequest
    |> where([r], r.target_id == ^user_id and r.game_id == ^game_id and r.status == ^status)
    |> order_by([r], desc: r.inserted_at)
    |> preload([:requester, :target, :game])
    |> Repo.all()
  end

  @doc """
  Liste les demandes envoyées par un user pour un jeu.
  """
  def list_sent_requests(user_id, game_id, opts \\ []) do
    status = Keyword.get(opts, :status, "pending")

    ConnectionRequest
    |> where([r], r.requester_id == ^user_id and r.game_id == ^game_id and r.status == ^status)
    |> order_by([r], desc: r.inserted_at)
    |> preload([:requester, :target, :game])
    |> Repo.all()
  end

  @doc """
  Vérifie si une demande existe déjà entre deux users pour un jeu.
  """
  def request_exists?(requester_id, target_id, game_id) do
    ConnectionRequest
    |> where([r],
      r.requester_id == ^requester_id and
      r.target_id == ^target_id and
      r.game_id == ^game_id and
      r.status == "pending"
    )
    |> Repo.exists?()
  end

  # ============================================================================
  # CONNECTIONS (relations établies)
  # ============================================================================

  @doc """
  Crée une connexion entre deux users pour un jeu.
  IMPORTANT: Utilise Connection.new() pour s'assurer que user_id_1 < user_id_2.
  """
  def create_connection(user_id_a, user_id_b, game_id) do
    Connection.new(user_id_a, user_id_b, game_id)
    |> Repo.insert()
  end

  @doc """
  Récupère une connexion entre deux users pour un jeu.
  """
  def get_connection(user_id_a, user_id_b, game_id) do
    {user_id_1, user_id_2} = order_user_ids(user_id_a, user_id_b)

    Connection
    |> where([c],
      c.user_id_1 == ^user_id_1 and
      c.user_id_2 == ^user_id_2 and
      c.game_id == ^game_id
    )
    |> preload([:game])
    |> Repo.one()
  end

  @doc """
  Vérifie si deux users sont connectés pour un jeu.
  """
  def has_connection?(user_id_a, user_id_b, game_id) do
    {user_id_1, user_id_2} = order_user_ids(user_id_a, user_id_b)

    Connection
    |> where([c],
      c.user_id_1 == ^user_id_1 and
      c.user_id_2 == ^user_id_2 and
      c.game_id == ^game_id
    )
    |> Repo.exists?()
  end

  @doc """
  Liste toutes les connexions d'un user pour un jeu.
  Retourne les users connectés avec les infos de la connexion.
  """
  def list_connections(user_id, game_id) do
    # Connexions où user est user_id_1
    connections_as_1 =
      Connection
      |> where([c], c.user_id_1 == ^user_id and c.game_id == ^game_id)
      |> preload([:game])
      |> Repo.all()

    # Connexions où user est user_id_2
    connections_as_2 =
      Connection
      |> where([c], c.user_id_2 == ^user_id and c.game_id == ^game_id)
      |> preload([:game])
      |> Repo.all()

    connections_as_1 ++ connections_as_2
  end

  @doc """
  Incrémente le compteur de parties jouées ensemble.
  """
  def increment_play_count(user_id_a, user_id_b, game_id) do
    case get_connection(user_id_a, user_id_b, game_id) do
      nil ->
        {:error, :not_connected}

      connection ->
        connection
        |> Connection.increment_play_count()
        |> Repo.update()
    end
  end

  @doc """
  Supprime une connexion (unfriend).
  """
  def delete_connection(user_id_a, user_id_b, game_id) do
    case get_connection(user_id_a, user_id_b, game_id) do
      nil ->
        {:error, :not_found}

      connection ->
        Repo.delete(connection)
    end
  end

  # ============================================================================
  # STATISTIQUES
  # ============================================================================

  @doc """
  Compte le nombre de connexions d'un user pour un jeu.
  """
  def count_connections(user_id, game_id) do
    count_as_1 =
      Connection
      |> where([c], c.user_id_1 == ^user_id and c.game_id == ^game_id)
      |> Repo.aggregate(:count)

    count_as_2 =
      Connection
      |> where([c], c.user_id_2 == ^user_id and c.game_id == ^game_id)
      |> Repo.aggregate(:count)

    count_as_1 + count_as_2
  end

  @doc """
  Compte le nombre de demandes en attente reçues.
  """
  def count_pending_requests(user_id, game_id) do
    ConnectionRequest
    |> where([r], r.target_id == ^user_id and r.game_id == ^game_id and r.status == "pending")
    |> Repo.aggregate(:count)
  end

  # ============================================================================
  # HELPERS PRIVÉS
  # ============================================================================

  defp order_user_ids(user_id_a, user_id_b) do
    if user_id_a < user_id_b do
      {user_id_a, user_id_b}
    else
      {user_id_b, user_id_a}
    end
  end
end
