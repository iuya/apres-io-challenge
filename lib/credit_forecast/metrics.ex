defmodule CreditForecast.Metrics do
  alias CreditForecast.Repo.Decisions

  # Receives a map which keys are the deltas we are interested in and calculates the difference
  # between both decisions.
  # Base is the original and snapshot is the updated version
  @spec add_deltas(map, Decisions.t(), Decisions.t()) :: map
  def add_deltas(deltas_acc, base_decision, snapshot_decision) do
    :maps.map(
      fn row_property, delta_list ->
        base_value = Map.get(base_decision.row, row_property)
        snapshot_value = Map.get(snapshot_decision.row, row_property)
        calculate_delta(delta_list, base_value, snapshot_value)
      end,
      deltas_acc
    )
  end

  defp calculate_delta(acc, base, snapshot) when is_number(base) and is_number(snapshot) do
    [snapshot - base, acc]
  end

  defp calculate_delta(acc, _base, _snapshot) do
    acc
  end
end
