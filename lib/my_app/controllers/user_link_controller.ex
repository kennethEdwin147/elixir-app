defmodule MyApp.Controllers.UserLinkController do
  use Plug.Router
  alias MyApp.Services.UserLinkStorage
  alias MyApp.Services.UserPageStorage
  alias MyApp.Services.Validation

  # Routes:
  # POST   /dashboard/pages/:page_id/links           → create (ajouter un lien)
  # PUT    /dashboard/pages/:page_id/links/:id       → update (modifier un lien)
  # DELETE /dashboard/pages/:page_id/links/:id       → delete (supprimer un lien)
  # POST   /dashboard/pages/:page_id/links/reorder   → reorder (réorganiser les liens)

  plug :match
  plug :dispatch

  # Créer un nouveau lien pour une page
  post "/:page_id" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["page_id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Vérifier que la page appartient à l'utilisateur
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        params = conn.params

        with {:ok, _} <- Validation.validate_required(params, ["url", "title"]),
             {:ok, _} <- validate_url(params["url"]),
             {:ok, _link} <- UserLinkStorage.create_link(
               page_id,
               params["url"],
               params["title"],
               params["icon"]
             ) do

          conn
          |> put_session(:success_msg, "Lien ajouté avec succès")
          |> put_resp_header("location", "/dashboard/pages/#{page_id}/edit")
          |> send_resp(302, "")

        else
          {:error, msg} ->
            conn
            |> put_session(:error_msg, msg)
            |> put_resp_header("location", "/dashboard/pages/#{page_id}/edit")
            |> send_resp(302, "")
        end
      else
        conn
        |> put_session(:error_msg, "Page non trouvée ou accès non autorisé")
        |> put_resp_header("location", "/dashboard/pages")
        |> send_resp(302, "")
      end
    end
  end

  # Modifier un lien existant
  put "/:page_id/:link_id" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["page_id"]
    link_id = conn.path_params["link_id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Vérifier que la page appartient au user
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        # Vérifier que le lien appartient à cette page
        link = UserLinkStorage.get_link_by_id(link_id)

        if link && link.page_id == page_id do
          params = conn.params

          with {:ok, _} <- validate_url_if_present(params["url"]),
               {:ok, updated_link} <- UserLinkStorage.update_link(link_id, params) do

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
          |> send_resp(403, Jason.encode!(%{success: false, error: "Lien non trouvé"}))
        end
      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{success: false, error: "Non autorisé"}))
      end
    end
  end

  # Supprimer un lien
  delete "/:page_id/:link_id" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["page_id"]
    link_id = conn.path_params["link_id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Vérifier que la page appartient au user
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        # Vérifier que le lien appartient à cette page
        link = UserLinkStorage.get_link_by_id(link_id)

        if link && link.page_id == page_id do
          case UserLinkStorage.delete_link(link_id) do
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
          |> send_resp(403, Jason.encode!(%{success: false, error: "Lien non trouvé"}))
        end
      else
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{success: false, error: "Non autorisé"}))
      end
    end
  end

  # Réorganiser les liens d'une page
  post "/:page_id/reorder" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["page_id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      # Vérifier que la page appartient au user
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        params = conn.params

        # params["link_ids"] devrait être une liste d'IDs dans le nouvel ordre
        # Ex: ["id1", "id3", "id2"]
        link_ids = params["link_ids"] || []

        case UserLinkStorage.reorder_links(page_id, link_ids) do
          {:ok, reordered_links} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{success: true, links: reordered_links}))

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
