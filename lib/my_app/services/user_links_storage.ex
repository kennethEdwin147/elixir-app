defmodule MyApp.Services.UserLinksStorage do
  @moduledoc """
  Gère les liens des utilisateurs sur le filesystem.

  Structure:
      priv/static/users/links/
      └── {user_id}.json
  """

  @links_dir "priv/static/users/links"

  defp links_file(user_id), do: Path.join(@links_dir, "#{user_id}.json")

  # Initialise le répertoire links
  defp init do
    File.mkdir_p!(@links_dir)
  end

  @doc """
  Récupère tous les liens d'un utilisateur.
  Retourne une liste de liens triés par position.
  """
  def get_user_links(user_id) do
    init()
    file = links_file(user_id)

    if File.exists?(file) do
      case File.read(file) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, links} ->
              links
              |> Enum.map(&atomize_keys/1)
              |> Enum.sort_by(& &1.position)
            {:error, _} -> []
          end
        {:error, _} -> []
      end
    else
      []
    end
  end

  @doc """
  Crée un nouveau lien pour un utilisateur.
  Retourne {:ok, link} ou {:error, reason}
  """
  def create_link(user_id, url, title, icon \\ nil) do
    init()

    links = get_user_links(user_id)
    next_position = length(links)

    link = %{
      id: generate_id(),
      user_id: user_id,
      url: url,
      title: title,
      icon: icon,
      position: next_position,
      clicks: 0,
      active: true,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    updated_links = links ++ [link]
    save_links(user_id, updated_links)

    {:ok, link}
  end

  @doc """
  Met à jour un lien existant.
  """
  def update_link(link_id, params) do
    # Trouver le user_id du link
    case find_link_with_user(link_id) do
      {user_id, link, links} ->
        updated_link = Map.merge(link, %{
          url: params["url"] || link.url,
          title: params["title"] || link.title,
          icon: params["icon"] || link.icon,
          active: if(Map.has_key?(params, "active"), do: params["active"], else: link.active)
        })

        updated_links = Enum.map(links, fn l ->
          if l.id == link_id, do: updated_link, else: l
        end)

        save_links(user_id, updated_links)
        {:ok, updated_link}

      nil ->
        {:error, "Lien non trouvé"}
    end
  end

  @doc """
  Supprime un lien.
  """
  def delete_link(link_id) do
    case find_link_with_user(link_id) do
      {user_id, _link, links} ->
        updated_links = Enum.reject(links, &(&1.id == link_id))
        # Réajuster les positions
        updated_links = Enum.with_index(updated_links)
        |> Enum.map(fn {link, index} -> %{link | position: index} end)

        save_links(user_id, updated_links)
        {:ok, "Lien supprimé"}

      nil ->
        {:error, "Lien non trouvé"}
    end
  end

  @doc """
  Réorganise l'ordre des liens.
  new_order est une liste d'IDs dans le nouvel ordre.
  """
  def reorder_links(user_id, new_order) do
    links = get_user_links(user_id)

    # Créer un map id -> link
    links_map = Map.new(links, &{&1.id, &1})

    # Réordonner selon new_order
    reordered_links = new_order
    |> Enum.with_index()
    |> Enum.map(fn {link_id, index} ->
      link = links_map[link_id]
      if link, do: %{link | position: index}, else: nil
    end)
    |> Enum.reject(&is_nil/1)

    save_links(user_id, reordered_links)
    {:ok, reordered_links}
  end

  @doc """
  Incrémente le compteur de clics d'un lien.
  """
  def increment_click(link_id) do
    case find_link_with_user(link_id) do
      {user_id, link, links} ->
        updated_link = %{link | clicks: link.clicks + 1}

        updated_links = Enum.map(links, fn l ->
          if l.id == link_id, do: updated_link, else: l
        end)

        save_links(user_id, updated_links)
        {:ok, updated_link}

      nil ->
        {:error, "Lien non trouvé"}
    end
  end

  @doc """
  Trouve un lien par son ID (pour le tracking).
  """
  def get_link_by_id(link_id) do
    case find_link_with_user(link_id) do
      {_user_id, link, _links} -> link
      nil -> nil
    end
  end

  # Helpers privés

  defp save_links(user_id, links) do
    file = links_file(user_id)
    # Convertir atoms en strings pour JSON
    links_json = Enum.map(links, &stringify_keys/1)
    File.write!(file, Jason.encode!(links_json))
  end

  defp find_link_with_user(link_id) do
    # Parcourir tous les fichiers de liens pour trouver celui qui contient link_id
    init()

    case File.ls(@links_dir) do
      {:ok, files} ->
        Enum.find_value(files, fn file ->
          user_id = Path.basename(file, ".json")
          links = get_user_links(user_id)

          case Enum.find(links, &(&1.id == link_id)) do
            nil -> nil
            link -> {user_id, link, links}
          end
        end)
      {:error, _} -> nil
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(12) |> Base.url_encode64(padding: false)
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
