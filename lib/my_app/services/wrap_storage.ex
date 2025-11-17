defmodule MyApp.Services.WrapStorage do
  @moduledoc """
  Gère la sauvegarde et le chargement des wraps sur le filesystem.
  """

  @uploads_dir "priv/static/uploads"
  @wraps_dir "priv/static/wraps"

  @doc """
  Sauvegarde les photos et le texte d'une slide.
  Retourne {:ok, slide_dir} ou {:error, reason}
  """
  def save_slide(wrap_id, step_num, photos, text) do
    slide_dir = Path.join([@uploads_dir, wrap_id, "slide_#{step_num}"])

    # Créer le dossier
    case File.mkdir_p(slide_dir) do
      :ok ->
        # Sauvegarder photos
        saved_photos = Enum.map(photos, fn photo ->
          # Générer un nom unique pour éviter collisions
          filename = "#{:crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)}_#{photo.filename}"
          destination = Path.join(slide_dir, filename)

          case File.cp(photo.path, destination) do
            :ok -> {:ok, filename}
            {:error, reason} -> {:error, reason}
          end
        end)

        # Check si erreurs
        errors = Enum.filter(saved_photos, fn
          {:error, _} -> true
          _ -> false
        end)

        if length(errors) > 0 do
          {:error, "Failed to save some photos"}
        else
          # Sauvegarder metadata (texte + liste photos)
          metadata = %{
            text: text,
            photos: Enum.map(saved_photos, fn {:ok, filename} -> filename end),
            created_at: DateTime.utc_now() |> DateTime.to_iso8601()
          }

          File.write!(Path.join(slide_dir, "metadata.json"), Jason.encode!(metadata))

          {:ok, slide_dir}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Charge les données d'une slide.
  Retourne %{photos: [...], text: "..."} ou nil
  """
  def load_slide(wrap_id, step_num) do
    slide_dir = Path.join([@uploads_dir, wrap_id, "slide_#{step_num}"])
    metadata_path = Path.join(slide_dir, "metadata.json")

    if File.exists?(metadata_path) do
      metadata_path
      |> File.read!()
      |> Jason.decode!()
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    else
      nil
    end
  end

  @doc """
  Charge toutes les slides d'un wrap.
  Retourne une liste de slides.
  """
  def load_all_slides(wrap_id) do
    1..7
    |> Enum.map(fn step_num ->
      case load_slide(wrap_id, step_num) do
        nil -> nil
        slide -> Map.put(slide, :step_num, step_num)
      end
    end)
    |> Enum.filter(& &1 != nil)
  end

  @doc """
  Crée le wrap final dans le dossier wraps.
  """
  def generate_wrap(wrap_id, template \\ "classic") do
    wrap_dir = Path.join(@wraps_dir, wrap_id)
    File.mkdir_p!(wrap_dir)

    # Charger toutes les slides
    slides = load_all_slides(wrap_id)

    # TODO: Générer le HTML avec les slides
    # Pour l'instant, juste créer un fichier marker
    File.write!(Path.join(wrap_dir, "generated.txt"), "Wrap generated at #{DateTime.utc_now()}")

    {:ok, wrap_dir}
  end
end
