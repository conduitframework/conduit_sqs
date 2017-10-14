defmodule ConduitSQS.Worker do
  use GenStage
  import Injex
  inject :message_processor, ConduitSQS.MessageProcessor

  defmodule State do
    defstruct [:broker, :name, :adapter_opts]
  end

  def start_link(broker, subscription_name, opts) do
    name = {:via, ConduitSQS.registry_name(broker), {__MODULE__, subscription_name}}

    GenStage.start_link(__MODULE__, [broker, subscription_name, opts], name: name)
  end

  def init([broker, name, opts]) do
    {:consumer, %State{
      broker: broker,
      name: name,
      adapter_opts: opts
    }, subscribe_to: [
      # TODO: Make max demand and min demand configurable
      {{:via, ConduitSQS.registry_name(broker), {ConduitSQS.Poller, name}}, []}
    ]}
  end

  def handle_events(messages, _from, %State{broker: broker, name: name, adapter_opts: opts} = state) do
    message_processor().process(broker, name, messages, opts)

    {:noreply, [], state}
  end
end
