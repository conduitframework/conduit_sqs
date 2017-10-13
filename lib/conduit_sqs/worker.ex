defmodule ConduitSQS.Worker do
  use GenStage

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
    }, subscriber_to: []}
  end

  def handle_events(messages, _from, %State{broker: broker, name: name} = state) do
    Enum.each(messages, &broker.receives(name, &1))

    {:noreply, [], state}
  end
end
