defmodule ConduitSQS.Worker do
  @moduledoc """
  Worker requests messages and processes them
  """
  use GenStage
  import Injex
  inject :message_processor, ConduitSQS.MessageProcessor

  defmodule State do
    @moduledoc false
    defstruct [:broker, :name, :adapter_opts]
  end

  @doc false
  def start_link(broker, subscription_name, num, opts) do
    name = {:via, Registry, {ConduitSQS.registry_name(broker), {__MODULE__, subscription_name, num}}}

    GenStage.start_link(__MODULE__, [broker, subscription_name, opts], name: name)
  end

  @doc false
  @impl true
  def init([broker, name, opts]) do
    poller_name = {:via, Registry, {ConduitSQS.registry_name(broker), {ConduitSQS.Poller, name}}}

    max_demand = Keyword.get(opts, :max_demand, 1000)
    min_demand = Keyword.get(opts, :min_demand, 500)

    {
      :consumer,
      %State{
        broker: broker,
        name: name,
        adapter_opts: opts
      },
      subscribe_to: [
        {poller_name, [max_demand: max_demand, min_demand: min_demand]}
      ]
    }
  end

  @doc false
  @impl true
  def handle_events(messages, _from, %State{broker: broker, name: name, adapter_opts: opts} = state) do
    message_processor().process(broker, name, messages, opts)

    {:noreply, [], state}
  end
end
