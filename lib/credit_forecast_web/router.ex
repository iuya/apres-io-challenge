defmodule CreditForecastWeb.Router do
  use CreditForecastWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CreditForecastWeb do
    pipe_through :api

    post("/query", QueryController, :get_matching_decisions)
  end
end
