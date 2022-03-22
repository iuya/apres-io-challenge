defmodule CreditForecast.Repo.Migrations.PopulateDecisionsTable do
  use Ecto.Migration

  alias NimbleCSV.RFC4180, as: CSV

  def change do
    "priv/credit_forecast_sample.csv"
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.map(fn [
                       forecast,
                       avg_payment,
                       avg_bill,
                       cred_score,
                       age,
                       sex,
                       marriage,
                       education,
                       last_payment
                     ] ->
      %{
        row: %{
          "FORECAST" => String.to_float(forecast),
          "AVERAGE PAYMENT" => String.to_float(avg_payment),
          "AVERAGE BILL" => String.to_float(avg_bill),
          "CREDIT SCORES" => String.to_integer(cred_score),
          "AGE" => :binary.copy(age),
          "SEX" => :binary.copy(sex),
          "MARRIAGE" => :binary.copy(marriage),
          "EDUCATION" => :binary.copy(education),
          "LAST PAYMENT" => :binary.copy(last_payment)
        }
      }
    end)
    |> Stream.chunk_every(1000)
    |> Stream.map(fn list_of_decisions ->
      CreditForecast.Repo.insert_all(CreditForecast.Repo.Decisions, list_of_decisions)
    end)
    |> Stream.run()
  end
end
