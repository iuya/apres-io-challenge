defmodule CreditForecast.StatefulQuery do
  @moduledoc """
  This GenServer emulates a linked list with a pointer which is able to traverse in both directions.
  This pointer however cannot get out of bounds, so it won't move when already at the beginning
  or end of the list and is requested to go to the previous or next respectively.
  """
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
  def handle_call(:get_next, _from, {traversed, [current | [next | to_traverse]]}) do
    {:reply, {:ok, next}, {[current | traversed], [next | to_traverse]}}
  end

  @impl true
  def handle_call(:get_next, _from, {_traversed, [_current | []]} = state) do
    {:reply, {:ok, nil}, state}
  end

  @impl true
  def handle_call(:get_prev, _from, {[], _traversing} = state) do
    {:reply, {:ok, nil}, state}
  end

  @impl true
  def handle_call(:get_prev, _from, {[prev | traversed], traversing}) do
    {:reply, {:ok, prev}, {traversed, [prev | traversing]}}
  end

  @impl true
  def handle_call({:add_operation, operation}, _from, {traversed, [current | to_traverse]}) do
    updated_entry = add_operation(current, operation)
    {:reply, {:ok, updated_entry}, {traversed, [updated_entry | to_traverse]}}
  end

  @impl true
  def handle_call({:add_operation, _operation}, _from, {traversed, []}) do
    {:reply, {:ok, nil}, {traversed, []}}
  end

  @impl true
  def handle_call(:dump, _from, {traversed, traversing} = state) do
    IO.inspect(traversed, label: :traversed)
    IO.inspect(traversing, label: :traversing)
    {:reply, {:ok, Enum.reverse(traversed, traversing)}, state}
  end

  defp add_operation({decision, journal}, operation) do
    {decision, [operation | journal]}
  end

  defp add_operation(decision, operation) do
    {decision, [operation]}
  end
end
