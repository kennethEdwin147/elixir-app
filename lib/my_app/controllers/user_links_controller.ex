defmodule MyApp.Controllers.UserLinksController do
  use Plug.Router
  alias MyApp.Services.UserLinksStorage
  alias MyApp.Services.Validation

  plug :match
  plug :dispatch

  # Créer un nouveau lien
  post "/" do
    user_id = get_session(conn, :user_id)

    # Vérifier si connecté
    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params

      with {:ok, _} <- Validation.validate_required(params, ["url", "title"]),
           {:ok, _} <- validate_url(params["url"]),
           {:ok, link} <- UserLinksStorage.create_link(
             user_id,
             params["url"],
             params["title"],
             params["icon"]
           ) do

        # Retourner JSON ou redirect vers dashboard
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{success: true, link: link}))

      else
        {:error, msg} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{success: false, error: msg}))
      end
    end
  end

  # Modifier un lien existant
  put "/:link_id" do
    user_id = get_session(conn, :user_id)
    link_id = conn.path_params["link_id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params

      # Vérifier que le lien appartient au user
      link = UserLinksStorage.get_link_by_id(link_id)

      if link && link.user_id == user_id do
        with {:ok, _} <- validate_url_if_present(params["url"]),
             {:ok, updated_link} <- UserLinksStorage.update_link(link_id, params) do

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{success: true, link: updated_link}))

        else
          {:error, msg} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{success: false, error: msg}))
        end
      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{success: false, error: "Non autorisé"}))
      end
    end
  end

  # Supprimer un lien
  delete "/:link_id" do
    user_id = get_session(conn, :user_id)
    link_id = conn.path_params["link_id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Vérifier que le lien appartient au user
      link = UserLinksStorage.get_link_by_id(link_id)

      if link && link.user_id == user_id do
        case UserLinksStorage.delete_link(link_id) do
          {:ok, _} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{success: true, message: "Lien supprimé"}))

          {:error, msg} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{success: false, error: msg}))
        end
      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{success: false, error: "Non autorisé"}))
      end
    end
  end

  # Réorganiser les liens
  post "/reorder" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params

      # params["link_ids"] devrait être une liste d'IDs dans le nouvel ordre
      # Ex: ["id1", "id3", "id2"]
      link_ids = params["link_ids"] || []

      case UserLinksStorage.reorder_links(user_id, link_ids) do
        {:ok, reordered_links} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{success: true, links: reordered_links}))

        {:error, msg} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{success: false, error: msg}))
      end
    end
  end

  # Helper pour valider une URL
  defp validate_url(url) when is_binary(url) do
    uri = URI.parse(url)

    if uri.scheme in ["http", "https"] && uri.host do
      {:ok, url}
    else
      {:error, "URL invalide (doit commencer par http:// ou https://)"}
    end
  end
  defp validate_url(_), do: {:error, "URL requise"}

  # Valider URL seulement si présente (pour update)
  defp validate_url_if_present(nil), do: {:ok, nil}
  defp validate_url_if_present(url), do: validate_url(url)

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
