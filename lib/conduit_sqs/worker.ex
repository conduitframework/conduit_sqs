defmodule ConduitSQS.Worker do
  use GenStage
  import Injex
  inject :message_processor, ConduitSQS.MessageProcessor

  defmodule State do
    defstruct [:broker, :name, :adapter_opts]
  end

  def start_link(broker, name, opts) do
    GenStage.start_link(__MODULE__, [broker, name, opts])
  end

  def init([broker, name, opts]) do
    {:consumer, %State{
      broker: broker,
      name: name,
      adapter_opts: opts
    }, subscribe_to: []}
  end

  def handle_events(messages, _from, %State{broker: broker, name: name, adapter_opts: opts} = state) do
    message_processor().process(broker, name, messages, opts)

    {:noreply, [], state}
  end
end
