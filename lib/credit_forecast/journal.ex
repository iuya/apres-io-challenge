defmodule CreditForecast.Journal do
  @moduledoc """
  A journal is list of operations to apply over a Decision struct. Since we have made this operations
  generic, we will only be able to apply those we have coded here
  """

  alias CreditForecast.Repo.Decisions

  @type operation :: {String.t(), String.t(), any()}
  @type t :: [operation()]

  def apply_operations({decision, journal}) do
    apply(decision, journal)
  end

  def apply_operations(decision, journal) do
    Enum.reduce(journal, decision, &apply_operation/2)
  end

  # We only know how to update 'FORECAST' but we can assume :update replaces any previous value
  # with the new one and have it work with any row property (even creating new ones if they don't
  # exist)
  def apply_operation({:update, row_property, value}, %Decisions{row: row} = decision) do
    %{decision | row: Map.put(row, row_property, value)}
  end

  # For all other operations we don't know what to do so we do nothing
  def apply_operation(_operation, decision) do
    decision
  end
end
