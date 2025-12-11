defmodule MyApp.Controllers.AnnouncementController do
  use Plug.Router
  alias MyApp.Services.AnnouncementService
  alias MyApp.Services.TagService
  alias MyApp.Services.Validator


  # Routes:
  # GET  /announcements/new            → Affiche formulaire de création
  # POST /announcements/new            → Crée une nouvelle annonce
  # POST /announcements/:id/complete   → Marque l'annonce comme terminée
  # POST /announcements/:id/delete     → Supprime l'annonce (si proprio)

  plug :match
  plug :dispatch

  # Affiche le formulaire de création
  get "/new" do
  # user_id = get_session(conn, :user_id)  # Commenté pour MVP

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

  # Crée l'annonce
  post "/new" do
    user_id = 1
    params = conn.params

    IO.inspect(params, label: "🔍 PARAMS")

    case Validator.validate(params, %{
      game: ["required", "string"],
      description: ["required", "string", {:min, 5}, {:max, 500}]
    }) do
      {:ok, _} ->
        parsed_tags = parse_tags(params["tags"])
        all_tags = ["##{params["game"]}" | parsed_tags] |> Enum.uniq()

        announcement_params = %{
          "game" => params["game"],
          "description" => params["description"],
          "user_id" => user_id,
          "tags" => Jason.encode!(all_tags)
        }

        case AnnouncementService.create(announcement_params) do
          {:ok, _announcement} ->
            conn
            |> put_resp_header("location", "/")
            |> send_resp(302, "")

          {:error, changeset} ->
            IO.inspect(changeset, label: "❌ CHANGESET ERROR")
            render_form_error(conn, params, "Erreur lors de la création de l'annonce")
        end

      {:error, validation_errors} ->  # ← Renommé pour clarté
        IO.inspect(validation_errors, label: "❌ VALIDATION ERRORS")
        error_msg = format_errors(validation_errors)
        render_form_error(conn, params, error_msg)
    end
  end

# ============================================================================
# FONCTIONS PRIVÉES
# ============================================================================

  defp parse_tags(tags) do
    case tags do
      "" -> []
      nil -> []
      tag_string when is_binary(tag_string) ->
        case Jason.decode(tag_string) do
          {:ok, list} -> list
          _ -> []
        end
      tag_list when is_list(tag_list) -> tag_list
    end
  end

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {_field, msg} -> msg end)
    |> Enum.join(", ")
  end

  defp render_form_error(conn, params, error_msg) do
    games = TagService.get_games()
    ranks = TagService.get_ranks()

    html = EEx.eval_file("lib/my_app/templates/create_announcement.html.eex",
      assigns: %{
        games: games,
        ranks: ranks,
        form_data: params,
        error_msg: error_msg
      }
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(400, html)
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

  # Upvote# Routes engagement
  post "/:id/upvote" do
    announcement_id = String.to_integer(id)
    user_id = conn.assigns[:current_user].id

    case AnnouncementService.toggle_upvote(announcement_id, user_id) do
      {:ok, :added} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "added"}))

      {:ok, :removed} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "removed"}))

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{error: "Announcement not found"}))
    end
  end

  post "/:id/interested" do
    announcement_id = String.to_integer(id)
    user_id = conn.assigns[:current_user].id

    case AnnouncementService.toggle_interested(announcement_id, user_id) do
      {:ok, :added} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "added"}))

      {:ok, :removed} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{status: "removed"}))

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{error: "Announcement not found"}))
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
