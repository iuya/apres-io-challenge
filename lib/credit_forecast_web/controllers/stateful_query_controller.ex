defmodule CreditForecastWeb.StatefulQueryController do
  use CreditForecastWeb, :controller

  alias CreditForecast.Service, as: QueryService

  def initate_stateful_query(conn, %{
        "column" => property_name,
        "operator" => op,
        "values" => value
      }) do
    with {:ok, id} <- QueryService.new(op, property_name, value) do
      {:ok, %{id: id}}
    end
    |> handle_response(conn)
  end

  def get_current(conn, %{"query_id" => id}) do
    id
    |> QueryService.get_current()
    |> handle_response(conn)
  end

  def get_next(conn, %{"query_id" => id}) do
    id
    |> QueryService.get_next()
    |> handle_response(conn)
  end

  def get_prev(conn, %{"query_id" => id}) do
    id
    |> QueryService.get_prev()
    |> handle_response(conn)
  end

  def dump(conn, %{"query_id" => id}) do
    id
    |> QueryService.dump()
    |> handle_response(conn)
  end

  def add_change_to_current(conn, %{
        "query_id" => id,
        "operation" => operation,
        "column" => property,
        "value" => value,
        "comment" => comment
      }) do
    id
    |> QueryService.add_operation(operation, property, {value, comment})
    |> handle_response(conn)
  end

  defp handle_response({:ok, res}, conn) do
    json(conn, res)
  end

  defp handle_response({:error, :internal_error, msg}, conn) do
    conn
    |> put_status(500)
    |> json(%{code: :internal_error, msg: msg})
  end

  defp handle_response({:error, :input_error, msg}, conn) do
    conn
    |> put_status(400)
    |> json(%{code: :input_error, msg: msg})
  end
end
