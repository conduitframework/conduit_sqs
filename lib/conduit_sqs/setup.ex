defmodule ConduitSQS.Setup do
  use GenServer
  import Injex
  inject :meta, ConduitSQS.Meta
  inject :sqs, ConduitSQS.SQS

  defmodule State do
    defstruct [:broker, :topology, :opts]
  end

  def start_link(broker, topology, opts) do
    GenServer.start_link(__MODULE__, [broker, topology, opts], name: __MODULE__)
  end

  def init([broker, topology, opts]) do
    Process.send(self(), :setup_topology, [])

    {:ok, %State{broker: broker, topology: topology, opts: opts}}
  end

  def handle_info(:setup_topology, %State{broker: broker, topology: topology, opts: opts} = state) do
    sqs().setup_topology(topology, opts)
    meta().activate_pollers(broker)

    {:stop, :normal, state}
  end
end
