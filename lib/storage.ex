defmodule Storage do
  use Agent
  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end
  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end
  def set(key, value, attrs \\ []) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))

    with {:ok, timer} <- Keyword.fetch(attrs, :timer) do
      :timer.apply_after(timer, __MODULE__, :delete, [key])
    end
  end

  def delete(key) do
    Agent.update(__MODULE__, &Map.delete(&1, key))
  end
end
