defmodule MyApp.Controllers.PostController do
  use Plug.Router
  alias MyApp.Services.{PostService, Validator, Policy, CommentService}

  plug :match
  plug :dispatch

  # Routes:
  # GET  /posts/new              → Formulaire de création (PROTÉGÉ)
  # POST /posts/new              → Crée un post (PROTÉGÉ)
  # POST /posts/:id/upvote       → Upvote (PUBLIC pour MVP)
  # POST /posts/:id/delete       → Supprime post (PROTÉGÉ + ownership)
  # POST /posts/:id/comments/:comment_id/delete → Supprime commentaire (PROTÉGÉ + ownership)

  # ============================================================================
  # FORMULAIRE DE CRÉATION
  # ============================================================================

  get "/new" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      ranks = ["Fer", "Bronze", "Argent", "Or", "Platine", "Diamant", "Ascendant", "Immortel", "Radiant"]
      regions = ["Any", "EU", "NA", "SA", "ASIA"]

      html = EEx.eval_file("lib/my_app/templates/create_post.html.eex",
        assigns: %{
          game: %{slug: "valorant", name: "Valorant"},  # Hardcodé MVP
          ranks: ranks,
          regions: regions,
          form_data: %{},
          error_msg: nil,
          current_user: current_user
        }
      )

      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(200, html)
    end
  end

  # ============================================================================
  # CRÉATION DE POST
  # ============================================================================

  post "/new" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      params = conn.params

      case Validator.validate(params, %{
        type: ["required", "string"],
        description: ["required", "string", {:min, 10}, {:max, 500}]
      }) do
        {:ok, _} ->
          validated_params = case params["type"] do
            "lfg" ->
              %{
                "type" => "lfg",
                "game" => "valorant",
                "rank" => params["rank"],
                "region" => params["region"],
                "contact" => params["contact"],
                "description" => params["description"],
                "user_id" => current_user.id
              }

            type when type in ["strat", "clip"] ->
              %{
                "type" => type,
                "game" => "valorant",
                "url" => params["url"],
                "description" => params["description"],
                "user_id" => current_user.id
              }
          end

          case PostService.create(validated_params) do
            {:ok, _post} ->
              conn
              |> put_resp_header("location", "/g/valorant")
              |> send_resp(302, "")

            {:error, changeset} ->
              IO.inspect(changeset, label: "❌ POST CREATE ERROR")
              render_form_error(conn, params, current_user, "Erreur lors de la création du post")
          end

        {:error, validation_errors} ->
          error_msg = format_errors(validation_errors)
          render_form_error(conn, params, current_user, error_msg)
      end
    end
  end

  # ============================================================================
  # UPVOTE
  # ============================================================================

  post "/:id/upvote" do
    post_id = String.to_integer(conn.path_params["id"])

    case PostService.upvote(post_id) do
      {:ok, post} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{score: post.score}))

      {:error, :not_found} ->
        conn
        |> send_resp(404, "Not found")
    end
  end

  # ============================================================================
  # SUPPRESSION POST
  # ============================================================================

  post "/:id/delete" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      post_id = String.to_integer(conn.path_params["id"])
      post = PostService.get(post_id)

      if Policy.can_delete_post?(current_user, post) do
        case PostService.delete(post_id, current_user.id) do
          {:ok, _} ->
            conn
            |> put_resp_header("location", "/g/valorant")
            |> send_resp(302, "")

          {:error, _} ->
            conn
            |> send_resp(403, "Erreur lors de la suppression")
        end
      else
        conn
        |> send_resp(403, "Non autorisé - ce n'est pas votre post")
      end
    end
  end

  # ============================================================================
  # SUPPRESSION COMMENTAIRE
  # ============================================================================

  post "/:post_id/comments/:id/delete" do
    current_user = conn.assigns[:current_user]

    unless current_user do
      conn
      |> put_resp_header("location", "/auth/login")
      |> send_resp(302, "")
    else
      post_id = conn.path_params["post_id"]
      comment_id = String.to_integer(conn.path_params["id"])
      comment = CommentService.get(comment_id)

      if Policy.can_delete_comment?(current_user, comment) do
        case CommentService.delete(comment_id) do
          {:ok, _} ->
            conn
            |> put_resp_header("location", "/g/valorant/posts/#{post_id}")
            |> send_resp(302, "")

          {:error, _} ->
            conn
            |> send_resp(403, "Erreur")
        end
      else
        conn
        |> send_resp(403, "Non autorisé")
      end
    end
  end

  # ============================================================================
  # FONCTIONS PRIVÉES
  # ============================================================================

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {_field, msg} -> msg end)
    |> Enum.join(", ")
  end

  defp render_form_error(conn, params, current_user, error_msg) do
    ranks = ["Fer", "Bronze", "Argent", "Or", "Platine", "Diamant", "Ascendant", "Immortel", "Radiant"]
    regions = ["Any", "EU", "NA", "SA", "ASIA"]

    html = EEx.eval_file("lib/my_app/templates/create_post.html.eex",
      assigns: %{
        game: %{slug: "valorant", name: "Valorant"},
        ranks: ranks,
        regions: regions,
        form_data: params,
        error_msg: error_msg,
        current_user: current_user
      }
    )

    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(400, html)
  end
end
