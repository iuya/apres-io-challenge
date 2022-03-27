defmodule CreditForecast.Metrics do
  @moduledoc """
  Handles generating metrics related to the operations done over the decisions
  """
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

  def calc_average_change(map_of_metrics, keys) do
    filtered_map = Map.take(map_of_metrics, keys)

    :maps.map(
      fn
        _key, [] ->
          0

        _key, values when is_list(values) ->
          {sum, total} =
            Enum.reduce(values, {0, 0}, fn value, {sum, count} -> {sum + value, count + 1} end)

          sum / total

        _key, value ->
          value
      end,
      filtered_map
    )
  end

  defp calculate_delta(acc, base, snapshot) when is_number(base) and is_number(snapshot) do
    [snapshot - base | acc]
  end

  defp calculate_delta(acc, _base, _snapshot) do
    acc
  end
end
