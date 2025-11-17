defmodule MyApp.Services.Validation do
  @doc """
  Vérifie que les champs requis ne sont pas vides.
  """
  def validate_required(params, fields) do
    case Enum.find(fields, fn f -> Map.get(params, f) in [nil, ""] end) do
      nil -> {:ok, params}
      missing -> {:error, "Le champ #{missing} est obligatoire"}
    end
  end

  @doc """
  Vérifie qu'un email contient bien un '@'.
  """
  def validate_email(email) do
    if email && String.contains?(email, "@") do
      {:ok, email}
    else
      {:error, "Email invalide"}
    end
  end

  @doc """
  Vérifie la longueur d'une chaîne et inclut le nom du champ dans l'erreur.
  Exemple: validate_length("Kenneth", "Prénom", min: 3, max: 10)
  """
  def validate_length(value, field_name, opts) do
    len = String.length(value || "")

    cond do
      opts[:min] && len < opts[:min] ->
        {:error, "Le champ #{field_name} a une longueur trop courte (min: #{opts[:min]})"}

      opts[:max] && len > opts[:max] ->
        {:error, "Le champ #{field_name} a une longueur trop longue (max: #{opts[:max]})"}

      true ->
        {:ok, value}
    end
  end

  @doc """
  Vérifie que deux champs (ex: password et confirmation) sont identiques.
  """
  def validate_confirmation(value, confirm, field_name \\ "champ") do
    if value == confirm do
      {:ok, value}
    else
      {:error, "#{field_name} et confirmation ne correspondent pas"}
    end
  end

  @doc """
  Vérifie qu'une valeur est un nombre et respecte des bornes éventuelles.
  Exemple: validate_number("42", min: 0, max: 100)
  """
  def validate_number(value, opts) do
    case Integer.parse(to_string(value || "")) do
      {num, _} ->
        cond do
          opts[:min] && num < opts[:min] ->
            {:error, "Nombre trop petit (min: #{opts[:min]})"}

          opts[:max] && num > opts[:max] ->
            {:error, "Nombre trop grand (max: #{opts[:max]})"}

          true ->
            {:ok, num}
        end

      :error ->
        {:error, "Valeur non numérique"}
    end
  end
end
