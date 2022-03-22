defmodule CreditForecast.Repo.Columns do
  @moduledoc """
  Defines a struct representing a row from the column table. It contains the name of the column
  and its type.
  """
  use Ecto.Schema

  alias CreditForecast.Repo

  schema "columns" do
    field :name, :string
    field :type, :string
  end

  def fetch_type(property) do
    case Repo.get_by(__MODULE__, name: property) do
      %__MODULE{type: type} -> {:ok, type}
      nil -> {:error, :not_found}
    end
  end
end
