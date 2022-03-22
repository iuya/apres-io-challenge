defmodule :"Elixir.CreditForecast.Repo.Migrations.Create-unique-index-for-columns-name" do
  use Ecto.Migration

  def change do
    unique_index("columns", ["name"])
  end
end
