defmodule CreditForecast.Repo do
  use Ecto.Repo,
    otp_app: :credit_forecast,
    adapter: Ecto.Adapters.Postgres
end
