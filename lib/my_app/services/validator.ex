defmodule MyApp.Services.Validator do
  @moduledoc """
  Validateur style Laravel avec règles de base
  """

  def validate(params, rules) do
    errors =
      Enum.flat_map(rules, fn {field, field_rules} ->
        value = params[to_string(field)]
        validate_field(field, value, field_rules, params)
      end)

    if Enum.empty?(errors) do
      {:ok, params}
    else
      {:error, Enum.into(errors, %{})}
    end
  end

  defp validate_field(field, value, rules, all_params) do
    Enum.reduce(rules, [], fn rule, acc ->
      error = check_rule(field, value, rule, all_params)
      if error, do: acc ++ [error], else: acc
    end)
  end

  # ============================================================================
  # RÈGLES DE VALIDATION
  # ============================================================================

  # Required
  defp check_rule(field, value, "required", _params) do
    if is_nil(value) or value == "" do
      {field, "Le champ #{field} est requis"}
    else
      nil
    end
  end

  # String
  defp check_rule(field, value, "string", _params) do
    if value && !is_binary(value) do
      {field, "#{field} doit être un texte"}
    else
      nil
    end
  end

  # Min length
  defp check_rule(field, value, {:min, min}, _params) do
    if value && String.length(value) < min do
      {field, "#{field} doit contenir au moins #{min} caractères"}
    else
      nil
    end
  end

  # Max length
  defp check_rule(field, value, {:max, max}, _params) do
    if value && String.length(value) > max do
      {field, "#{field} ne peut pas dépasser #{max} caractères"}
    else
      nil
    end
  end

  # Email format
  defp check_rule(field, value, "email", _params) do
    if value && !String.match?(value, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
      {field, "#{field} doit être une adresse email valide"}
    else
      nil
    end
  end

  # Same as (compare avec un autre champ)
  defp check_rule(field, value, {:same_as, other_field}, params) do
    other_value = params[other_field]

    if value != other_value do
      {field, "Le champ #{field} doit correspondre à #{other_field}"}
    else
      nil
    end
  end

  # In (valeur doit être dans une liste)
  defp check_rule(field, value, {:in, allowed_values}, _params) do
    if value && value not in allowed_values do
      {field, "#{field} doit être l'une des valeurs suivantes : #{Enum.join(allowed_values, ", ")}"}
    else
      nil
    end
  end

  # Numeric
  defp check_rule(field, value, "numeric", _params) do
    if value && !is_number(value) && !is_numeric_string?(value) do
      {field, "#{field} doit être un nombre"}
    else
      nil
    end
  end

  # Between (nombre entre min et max)
  defp check_rule(field, value, {:between, min, max}, _params) do
    num = to_number(value)
    if num && (num < min || num > max) do
      {field, "#{field} doit être entre #{min} et #{max}"}
    else
      nil
    end
  end

  # Alpha (seulement lettres)
  defp check_rule(field, value, "alpha", _params) do
    if value && !String.match?(value, ~r/^[a-zA-Z]+$/) do
      {field, "#{field} ne peut contenir que des lettres"}
    else
      nil
    end
  end

  # Alpha numeric
  defp check_rule(field, value, "alpha_numeric", _params) do
    if value && !String.match?(value, ~r/^[a-zA-Z0-9]+$/) do
      {field, "#{field} ne peut contenir que des lettres et chiffres"}
    else
      nil
    end
  end

  # Règle inconnue = ignore
  defp check_rule(_field, _value, _rule, _params), do: nil

  # ============================================================================
  # HELPERS
  # ============================================================================

  defp is_numeric_string?(value) when is_binary(value) do
    case Float.parse(value) do
      {_num, ""} -> true
      _ -> false
    end
  end
  defp is_numeric_string?(_), do: false

  defp to_number(value) when is_number(value), do: value
  defp to_number(value) when is_binary(value) do
    case Float.parse(value) do
      {num, ""} -> num
      _ -> nil
    end
  end
  defp to_number(_), do: nil
end
