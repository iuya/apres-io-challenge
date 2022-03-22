defmodule CreditForecastWeb.QueryController do
  use CreditForecastWeb, :controller

  alias CreditForecast.Repo.Decisions

  def get_matching_decisions(conn, %{
        "column" => property_name,
        "operator" => op,
        "values" => value
      }) do
    decisions = Decisions.get_matching(op, property_name, value)
    json(conn, decisions)
  end
end
