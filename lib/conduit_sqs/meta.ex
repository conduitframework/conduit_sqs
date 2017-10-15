defmodule ConduitSQS.Meta do
  def activate_pollers(broker) do
    broker
    |> meta_name()
    |> :ets.insert({:active, true})
  end

  def pollers_active?(broker) do
    broker
    |> meta_name()
    |> :ets.lookup(:active)
    |> case do
      [] -> false
      [{:active, value} | _] -> value
    end
  end

  def create(broker) do
    broker
    |> meta_name()
    |> :ets.new([:set, :public, :named_table])
  end

  defp meta_name(broker) do
    Module.concat([broker, Meta])
  end
end
