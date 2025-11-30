defmodule MyApp.Controllers.UserPageController do
  use Plug.Router
  alias MyApp.Services.UserPageStorage
  alias MyApp.Services.Validation

  # Routes:
  # GET    /dashboard/pages          → index (liste des pages)
  # GET    /dashboard/pages/new      → new (formulaire création)
  # POST   /dashboard/pages          → create
  # GET    /dashboard/pages/:id/edit → edit (formulaire édition)
  # PUT    /dashboard/pages/:id      → update
  # DELETE /dashboard/pages/:id      → delete

  plug :match
  plug :dispatch

  # Liste toutes les pages de l'utilisateur
  get "/" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      pages = UserPageStorage.get_user_pages(user_id)

      # Render template EEx
      html = MyApp.Templates.UserPage.index(%{
        pages: pages,
        success_msg: get_session(conn, :success_msg),
        error_msg: get_session(conn, :error_msg)
      })

      conn
      |> delete_session(:success_msg)
      |> delete_session(:error_msg)
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
    end
  end

  # Affiche le formulaire de création
  get "/new" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      html = MyApp.Templates.UserPage.new(%{
        error_msg: get_session(conn, :error_msg)
      })

      conn
      |> delete_session(:error_msg)
      |> put_resp_content_type("text/html")
      |> send_resp(200, html)
    end
  end

  # Créer une nouvelle page
  post "/" do
    user_id = get_session(conn, :user_id)

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params

      with {:ok, _} <- Validation.validate_required(params, ["slug", "title"]),
           {:ok, _} <- validate_slug(params["slug"]),
           {:ok, page} <- UserPageStorage.create_page(
             user_id,
             params["slug"],
             params["title"],
             params["bio"],
             params["avatar_url"],
             params["is_primary"] == "true"
           ) do

        conn
        |> put_session(:success_msg, "Page créée avec succès")
        |> put_resp_header("location", "/dashboard/pages/#{page.id}/edit")
        |> send_resp(302, "")

      else
        {:error, msg} ->
          conn
          |> put_session(:error_msg, msg)
          |> put_resp_header("location", "/dashboard/pages/new")
          |> send_resp(302, "")
      end
    end
  end

  # Affiche le formulaire d'édition
  get "/:id/edit" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        # Récupérer aussi les liens de cette page
        links = UserPageStorage.get_page_links(page_id)

        html = MyApp.Templates.UserPage.edit(%{
          page: page,
          links: links,
          success_msg: get_session(conn, :success_msg),
          error_msg: get_session(conn, :error_msg)
        })

        conn
        |> delete_session(:success_msg)
        |> delete_session(:error_msg)
        |> put_resp_content_type("text/html")
        |> send_resp(200, html)
      else
        conn
        |> put_session(:error_msg, "Page non trouvée ou accès non autorisé")
        |> put_resp_header("location", "/dashboard/pages")
        |> send_resp(302, "")
      end
    end
  end

  # Mettre à jour une page
  put "/:id" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        params = conn.params

        with {:ok, _} <- validate_slug_if_present(params["slug"]),
             {:ok, _updated_page} <- UserPageStorage.update_page(page_id, params) do

          conn
          |> put_session(:success_msg, "Page mise à jour avec succès")
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

  # Supprimer une page
  delete "/:id" do
    user_id = get_session(conn, :user_id)
    page_id = conn.path_params["id"]

    if is_nil(user_id) do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      page = UserPageStorage.get_page_by_id(page_id)

      if page && page.user_id == user_id do
        case UserPageStorage.delete_page(page_id) do
          {:ok, _} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{success: true, message: "Page supprimée"}))

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

  # Validation du slug (URL-friendly)
  defp validate_slug(slug) when is_binary(slug) do
    # Slug doit contenir seulement lettres, chiffres, tirets et underscores
    if Regex.match?(~r/^[a-z0-9_-]+$/i, slug) do
      {:ok, slug}
    else
      {:error, "Le slug doit contenir uniquement des lettres, chiffres, tirets et underscores"}
    end
  end
  defp validate_slug(_), do: {:error, "Slug requis"}

  # Valider slug seulement si présent (pour update)
  defp validate_slug_if_present(nil), do: {:ok, nil}
  defp validate_slug_if_present(slug), do: validate_slug(slug)

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
