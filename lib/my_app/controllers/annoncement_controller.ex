defmodule MyApp.Controllers.AnnouncementController do
  use Plug.Router
  alias MyApp.Services.AnnouncementService
  alias MyApp.Services.TagService
  alias MyApp.Services.Validation

  # Routes:
  # GET  /announcements/new            → Affiche formulaire de création
  # POST /announcements/new            → Crée une nouvelle annonce
  # POST /announcements/:id/complete   → Marque l'annonce comme terminée
  # POST /announcements/:id/delete     → Supprime l'annonce (si proprio)

  plug :match
  plug :dispatch

  # Affiche le formulaire de création
  get "/new" do
    user_id = get_session(conn, :user_id)

    unless user_id do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      games = TagService.get_games()
      ranks = TagService.get_ranks()

      html = EEx.eval_file("lib/my_app/templates/create_announcement.html.eex",
        assigns: %{
          games: games,
          ranks: ranks,
          form_data: %{},
          error_msg: nil
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  # Crée l'annonce
  post "/new" do

    user_id = get_session(conn, :user_id)

  # DEBUG ICI ⬇️
  IO.inspect(user_id, label: "🔍 USER_ID FROM SESSION")
  IO.inspect(is_integer(user_id), label: "🔍 IS INTEGER?")
  IO.inspect(is_binary(user_id), label: "🔍 IS STRING?")



    unless user_id do
      conn
      |> put_resp_header("location", "/login")
      |> send_resp(302, "")
    else
      params = conn.params

      # Validation basique (juste game et description maintenant)
      with {:ok, _} <- Validation.validate_required(params, ["game", "description"]) do

        # Construire les tags automatiquement
        tags = build_tags_from_input(params)

        announcement_params = Map.merge(params, %{
          "user_id" => user_id,
          "tags" =>  Jason.encode!(tags)
        })

        case AnnouncementService.create(announcement_params) do
          {:ok, _announcement} ->
            conn
            |> put_resp_header("location", "/")
            |> send_resp(302, "")

          {:error, changeset} ->
                IO.inspect(changeset, label: "CHANGESET ERROR")

            games = TagService.get_games()
            ranks = TagService.get_ranks()

            html = EEx.eval_file("lib/my_app/templates/create_announcement.html.eex",
              assigns: %{
                games: games,
                ranks: ranks,
                form_data: params,
                error_msg: "Erreur lors de la création de l'annonce"
              }
            )

            conn
            |> put_resp_content_type("text/html", "utf-8")
            |> send_resp(400, html)
        end
      else
        _ ->
          games = TagService.get_games()
          ranks = TagService.get_ranks()

          html = EEx.eval_file("lib/my_app/templates/create_announcement.html.eex",
            assigns: %{
              games: games,
              ranks: ranks,
              form_data: params,
              error_msg: "Champs requis manquants"
            }
          )

          conn
          |> put_resp_content_type("text/html", "utf-8")
          |> send_resp(400, html)
      end
    end
  end

  # Marquer comme terminé
  post "/:id/complete" do
    user_id = get_session(conn, :user_id)
    announcement_id = conn.path_params["id"]

    case AnnouncementService.mark_complete(announcement_id, user_id) do
      {:ok, _} ->
        conn
        |> put_resp_header("location", "/")
        |> send_resp(302, "")

      {:error, _} ->
        conn
        |> put_resp_header("location", "/")
        |> send_resp(302, "")
    end
  end

  # Supprimer
  post "/:id/delete" do
    user_id = get_session(conn, :user_id)
    announcement_id = conn.path_params["id"]

    case AnnouncementService.delete(announcement_id, user_id) do
      {:ok, _} ->
        conn
        |> put_resp_header("location", "/")
        |> send_resp(302, "")

      {:error, _} ->
        conn
        |> put_resp_header("location", "/")
        |> send_resp(302, "")
    end
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  # Construit les tags depuis le formulaire
  defp build_tags_from_input(params) do
    # Tags auto depuis form (jeu, rang, vibe)
    auto_tags = TagService.build_tags(params)

    # Tags manuels tapés par l'user
    manual_tags = case params["tags_input"] do
      nil -> []
      "" -> []
      text ->
        text
        |> String.split(" ", trim: true)
        |> Enum.map(&String.trim/1)
        |> Enum.map(fn tag ->
          if String.starts_with?(tag, "#"), do: tag, else: "##{tag}"
        end)
    end

    # Combine et retire doublons
    (auto_tags ++ manual_tags) |> Enum.uniq()
  end
end
