defmodule CreditForecast.Repo.Migrations.AddColumnsTable do
  use Ecto.Migration

  def change do
    create table("columns") do
      add :name, :string
      add :type, :string
    end

    Ecto.Migration.flush()

    columns = [
      %{name: "FORECAST", type: "float"},
      %{name: "AVERAGE PAYMENT", type: "float"},
      %{name: "AVERAGE BILL", type: "float"},
      %{name: "CREDIT SCORES", type: "integer"},
      %{name: "AGE", type: "string"},
      %{name: "SEX", type: "string"},
      %{name: "MARRIAGE", type: "string"},
      %{name: "EDUCATION", type: "string"},
      %{name: "LAST PAYMENT", type: "string"}
    ]

    CreditForecast.Repo.insert_all(CreditForecast.Repo.Columns, columns)
  end
end
