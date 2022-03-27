defmodule CreditForecast.Service do
  alias CreditForecast.Repo.Decisions
  alias CreditForecast.Journal
  alias CreditForecast.Metrics
  alias CreditForecast.StatefulQuery
  alias CreditForecast.QueryRegistry

  @type operation :: String.t()
  @type property_name :: String.t()
  @type error :: {:error, code :: atom, msg :: String.t()}

  @spec new(operation, property_name, value :: any()) :: {:ok, Decision.t()} | error()
  def new(operation, property_name, value) do
    id = UUID.uuid4()
    name = {:via, Registry, {QueryRegistry, id}}

    with {:ok, decisions} <- Decisions.get_matching(operation, property_name, value),
         {:ok, _pid} <- GenServer.start_link(StatefulQuery, decisions, name: name) do
      {:ok, id}
    end
  end

  def get_current(id) do
    with [{pid, _}] <- Registry.lookup(QueryRegistry, id),
         {:ok, entry} <- GenServer.call(pid, :get_current) do
      {:ok, Journal.apply_operations(entry)}
    else
      other -> {:error, :internal_error, inspect(other)}
    end
  end

  def get_next(id) do
    with [{pid, _}] <- Registry.lookup(QueryRegistry, id),
         {:ok, entry} <- GenServer.call(pid, :get_next) do
      {:ok, Journal.apply_operations(entry)}
    end
  end

  def get_prev(id) do
    with [{pid, _}] <- Registry.lookup(QueryRegistry, id),
         {:ok, entry} <- GenServer.call(pid, :get_prev) do
      {:ok, Journal.apply_operations(entry)}
    end
  end

  def add_operation(id, operation, property, value) do
    with [{pid, _}] <- Registry.lookup(QueryRegistry, id),
         {:ok, entry} <- GenServer.call(pid, {:add_operation, {operation, property, value}}) do
      {:ok, Journal.apply_operations(entry)}
    end
  end

  def dump(id) do
    with [{pid, _}] <- Registry.lookup(QueryRegistry, id),
         {:ok, entries} <- GenServer.call(pid, :dump),
         {entries, metrics} <-
           Enum.map_reduce(
             entries,
             %{"FORECAST" => [], "CHANGES" => 0},
             &build_raw_decision_dump/2
           ) do
      IO.inspect(metrics, label: "metrics")
      metrics_summary = Metrics.calc_average_change(metrics, ["FORECAST", "CHANGES"])
      {:ok, %{decisions: entries, metrics: metrics_summary}}
    end
  end

  defp build_raw_decision_dump({%Decisions{} = decision, journal} = entry, metrics_acc) do
    # IO.inspect(entry, label: "entry")
    # IO.inspect(deltas_acc, label: "accumulator")

    serializable_journal =
      Enum.map(journal, fn {operation, column, {value, comment}} ->
        %{
          operation: operation,
          property: column,
          value: value,
          comment: comment
        }
      end)

    decision_snapshot =
      entry
      |> Journal.apply_operations()
      |> Map.from_struct()
      |> Map.take([:row])
      |> Map.put(:journal, serializable_journal)

    updated_metrics =
      metrics_acc
      |> Metrics.add_deltas(decision, decision_snapshot)
      |> Map.update("CHANGES", 0, fn value -> value + 1 end)

    {decision_snapshot, updated_metrics}
  end

  # This case is so we skip generating metrics for decisions w/o a journal
  defp build_raw_decision_dump(denormalized_decision, deltas_acc) do
    {denormalized_decision, deltas_acc}
  end
end
