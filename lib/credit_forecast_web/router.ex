defmodule CreditForecastWeb.Router do
  use CreditForecastWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CreditForecastWeb do
    pipe_through :api

    post("/decisions", QueryController, :get_matching_decisions)

    scope("/query") do
      post("/", StatefulQueryController, :initate_stateful_query)
      get("/:query_id", StatefulQueryController, :get_current)
      get("/:query_id/next", StatefulQueryController, :get_next)
      get("/:query_id/prev", StatefulQueryController, :get_prev)
      post("/:query_id", StatefulQueryController, :add_change_to_current)
      get("/:query_id/dump", StatefulQueryController, :dump)
    end
  end
end
