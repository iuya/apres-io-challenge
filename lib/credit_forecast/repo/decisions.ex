defmodule CreditForecast.Repo.Decisions do
  @moduledoc """
  Defines a struct representing a row from the decision table. It contains just 1 field which is
  a jsonb from postgres (although decisions technically have an ID we don't care about it)
  """
  use Ecto.Schema

  import Ecto.Query

  alias CreditForecast.Repo
  alias CreditForecast.Repo.Columns

  @operators ["eq", "gt"]

  @derive {Jason.Encoder, only: [:row]}
  schema "decisions" do
    field :row, :map
  end

  def get_matching(operator, property, value) do
    with :ok <- validate_query_params(operator, property, value),
         {:ok, type} <- Columns.fetch_type(property),
         {:ok, query} <- build_query(operator, type, property, value) do
      {:ok, Repo.all(query)}
    else
      {:error, code, msg} when code in [:not_found, :unsupported_operation, :input_error] ->
        {:error, :input_error, msg}

      other ->
        {:error, :internal_error, "unexpected error: #{inspect(other)}"}
    end
  end

  # We can do some basic checks to see if there is no need to hit the DB
  def validate_query_params(:gt, _property, value) when not is_number(value),
    do: {:error, :input_error, "cannot use 'gt' operator for non numeric values"}

  def validate_query_params(op, _property, _value) when op not in @operators,
    do: {:error, :input_error, "invalid operator '#{op}, options are #{inspect(@operators)}"}

  def validate_query_params(_, _, _), do: :ok

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
    {:error, :unsupported_operation, "cannot generate query with given parameters"}
  end
end
