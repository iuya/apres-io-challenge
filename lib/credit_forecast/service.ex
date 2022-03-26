defmodule CreditForecast.Service do
  alias CreditForecast.Repo.Decisions
  alias CreditForecast.Journal
  alias CreditForecast.Metrics

  @type operation :: String.t()
  @type property_name :: String.t()
  @type error :: {:error, code :: atom, msg :: String.t()}

  @spec new(operation, property_name, value :: any()) :: {:ok, Decision.t()} | error()
  def new(operation, property_name, value) do
    id = UUID.uuid4()
    name = {:via, Registry, {CreditForecast.QueryRegistry, id}}

    with {:ok, decisions} <- Decisions.get_matching(operation, property_name, value),
         {:ok, _pid} <- GenServer.start_link(StatefulQuery, decisions, name: name) do
      {:ok, id}
    end
  end

  def get_current(id) do
    with [{_, query_pid}] <- Registry.lookup(Registry.ViaTest, id),
         {:ok, entry} <- GenServer.call(query_pid, :get_current) do
      {:ok, apply_operations(entry)}
    end
  end

  def get_next(id) do
    with [{_, query_pid}] <- Registry.lookup(Registry.ViaTest, id),
         {:ok, entry} <- GenServer.call(query_pid, :get_next) do
      {:ok, apply_operations(entry)}
    end
  end

  def get_prev(id) do
    with [{_, query_pid}] <- Registry.lookup(Registry.ViaTest, id),
         {:ok, entry} <- GenServer.call(query_pid, :get_prev) do
      {:ok, apply_operations(entry)}
    end
  end

  def add_operation(id, operation, property, value) do
    with [{_, query_pid}] <- Registry.lookup(Registry.ViaTest, id),
         {:ok, entry} <- GenServer.call(query_pid, {:add_operation, [operation, property, value]}) do
      {:ok, apply_operations(entry)}
    end
  end

  def dump(id) do
    with [{_, query_pid}] <- Registry.lookup(Registry.ViaTest, id),
         {:ok, entries} <- GenServer.call(query_pid, :dump) do
      dump_with_metrics =
        Enum.map_reduce(entries, %{"FORECAST" => []}, fn entry, deltas_acc ->
          {decision, journal} = normalize_entry(entry)
          decision_snapshot = Journal.apply_operations(decision, journal)
          updated_deltas = Metrics.add_deltas(deltas_acc, decision, decision_snapshot)
          {decision_snapshot, updated_deltas}
        end)

      {:ok, dump_with_metrics}
    end
  end

  defp apply_operations(entry) do
    entry
    |> normalize_entry()
    |> Journal.apply_operations()
  end

  defp normalize_entry({_decision, _journal} = already_normalized) do
    already_normalized
  end

  defp normalize_entry(denormalized_decision) do
    {denormalized_decision, []}
  end
end
