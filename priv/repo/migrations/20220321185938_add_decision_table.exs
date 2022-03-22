defmodule CreditForecast.Repo.Migrations.AddDecisionTable do
  use Ecto.Migration

  def change do
    create table("decisions") do
      add :row, :jsonb
    end
  end
end
