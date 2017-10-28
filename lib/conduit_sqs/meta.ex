defmodule ConduitSQS.Meta do
  @moduledoc """
  Facilitates setup communication to pollers that queues are available
  """

  @type broker :: atom

  @doc """
  Sets a flag that pollers use to know that setup is complete
  """
  @spec activate_pollers(broker) :: true
  def activate_pollers(broker) do
    broker
    |> meta_name()
    |> :ets.insert({:active, true})
  end

  @doc """
  Returns whether setup has been completed
  """
  @spec pollers_active?(broker) :: boolean
  def pollers_active?(broker) do
    broker
    |> meta_name()
    |> :ets.lookup(:active)
    |> case do
      [] -> false
      [{:active, value} | _] -> value
    end
  end

  @doc """
  Creates an ETS table to store whether setup has been completed
  """
  @spec create(broker) :: atom
  def create(broker) do
    broker
    |> meta_name()
    |> :ets.new([:set, :public, :named_table])
  end

  defp meta_name(broker) do
    Module.concat([broker, Meta])
  end
end
