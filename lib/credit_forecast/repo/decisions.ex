defmodule CreditForecast.Repo.Decisions do
  @moduledoc """
  Defines a struct representing a row from the decision table. It contains just 1 field which is
  a jsonb from postgres (although decisions technically have an ID we don't care about it)
  """
  use Ecto.Schema

  import Ecto.Query

  alias CreditForecast.Repo
  alias CreditForecast.Repo.Columns

  @valid_operators ["eq", "gt"]

  @derive {Jason.Encoder, only: [:row]}
  schema "decisions" do
    field :row, :map
  end

  # These matches are here to shortcircuit the flow and skip querying the column table when we
  # already know it's going to fail in the `build_query` function.
  def get_matching(:gt, _property, value) when not is_number(value) do
    {:error, "cannot use 'gt' operator for non numeric values"}
  end

  def get_matching(operator, _property, _value) when operator not in @valid_operators do
    {:error, "invalid operator '#{operator}, valid options are #{inspect(@valid_operators)}"}
  end

  def get_matching(operator, property, value) do
    with {:ok, type} <- Columns.fetch_type(property),
         {:ok, query} <- build_query(operator, type, property, value) do
      Repo.all(query)
    else
      {:error, :not_found} ->
        {:error, "property '#{property}' does not exist"}

      {:error, :unsupported_operation} ->
        {:error, "cannot generate query with given parameters"}
    end
  end

  # Since we can't use string interpolation for the fragments as Ecto detects a potential SQL
  # injection, we have to hardcode all the queries here.
  defp build_query("gt", "float", property, value) do
    {:ok, from(d in __MODULE__, where: fragment("(row->>?)::float > ?", ^property, ^value))}
  end

  defp build_query("gt", "integer", property, value) do
    {:ok, from(d in __MODULE__, where: fragment("(row->>?)::integer > ?", ^property, ^value))}
  end

  defp build_query("eq", "float", property, value) do
    {:ok, from(d in __MODULE__, where: fragment("(row->>?)::float = ?", ^property, ^value))}
  end

  defp build_query("eq", "integer", property, value) do
    {:ok, from(d in __MODULE__, where: fragment("(row->>?)::integer = ?", ^property, ^value))}
  end

  defp build_query("eq", "string", property, value) do
    {:ok, from(d in __MODULE__, where: fragment("(row->>?)::varchar = ?", ^property, ^value))}
  end

  defp build_query(_op, _type, _property, _value) do
    {:error, :unsupported_operation}
  end
end
