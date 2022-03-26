defmodule CreditForecast.StatefulQuery do
  use GenServer

  alias CreditForecast.Repo.Decisions
  alias CreditForecast.Repo.Journal

  @type entry :: {Decisions.t(), Journal.t()} | Decisions.t()

  @impl true
  def init(decisions) do
    {:ok, {[], decisions}}
  end

  @impl true
  def handle_call(:get_current, _from, {_traversed, [current | _to_traverse]} = state) do
    {:reply, {:ok, current}, state}
  end

  @impl true
  def handle_call(:get_current, _from, {_traversed, []} = state) do
    {:reply, {:ok, []}, state}
  end

  @impl true
  def handle_call(:get_next, _from, {traversed, [current | [next | to_traverse]]}) do
    {:reply, {:ok, next}, {[current | traversed], [next | to_traverse]}}
  end

  @impl true
  def handle_call(:get_next, _from, {traversed, [current | []]}) do
    {:reply, {:ok, nil}, {[current | traversed], []}}
  end

  @impl true
  def handle_call(:get_prev, _from, {[prev | traversed], traversing}) do
    {:reply, {:ok, prev}, {traversed, [prev, traversing]}}
  end

  @impl true
  def handle_call(:get_prev, _from, {[], _traversing} = state) do
    {:reply, {:ok, nil}, state}
  end

  @impl true
  def handle_call({:add_operation, operation}, _from, {traversed, [current | to_traverse]}) do
    updated_entry = add_operation(current, operation)
    {:reply, {:ok, updated_entry}, {traversed, [updated_entry | to_traverse]}}
  end

  @impl true
  def handle_call({:add_operation, _operation}, _from, {traversed, []}) do
    {:reply, {:error, :end_reached}, {traversed, []}}
  end

  @impl true
  def handle_call(:dump, _from, {traversed, traversing} = state) do
    {:reply, {:ok, Enum.reverse(traversed, traversing)}, state}
  end

  defp add_operation({decision, journal}, operation) do
    {decision, [operation, journal]}
  end

  defp add_operation(decision, operation) do
    {decision, [operation]}
  end
end
