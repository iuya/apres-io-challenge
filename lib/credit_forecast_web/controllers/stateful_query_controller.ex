defmodule CreditForecastWeb.StatefulQueryController do
  use CreditForecastWeb, :controller

  def initate_stateful_query(conn, %{
        "column" => property_name,
        "operator" => op,
        "values" => value
      }) do
    case QueryService.new(op, property_name, value) do
      {:error, :input_error, msg} ->
        conn
        |> put_status(400)
        |> json(%{code: :input_error, msg: msg})

      {:error, :internal_error, msg} ->
        conn
        |> put_status(500)
        |> json(%{code: :internal_error, msg: msg})

      {:ok, decisions} ->
        json(conn, decisions)
    end
  end

  def get_current(conn, %{query_id: qid}) do
    QueryService.get(qid)
  end

  def get_next(conn, %{query_id: qid}) do
    QueryService.next(qid)
  end

  def get_prev(conn, %{query_id: qid}) do
    QueryService.previous(qid)
  end

  def add_change_to_current(conn, %{
        "query_id" => qid,
        "operation" => operation,
        "column" => property,
        "value" => value
      }) do
    QueryService.add_operation(qid, operation, property, value)
  end
end
