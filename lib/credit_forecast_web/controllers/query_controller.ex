defmodule CreditForecastWeb.QueryController do
  use CreditForecastWeb, :controller

  alias CreditForecast.Repo.Decisions

  def get_matching_decisions(conn, %{
        "column" => property_name,
        "operator" => op,
        "values" => value
      }) do
    case Decisions.get_matching(op, property_name, value) do
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
end
