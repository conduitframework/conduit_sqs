defmodule ConduitSQS.Setup do
  @moduledoc """
  Creates queues at startup and notifies pollers to start
  """
  use GenServer
  import Injex
  inject :meta, ConduitSQS.Meta
  inject :sqs, ConduitSQS.SQS

  defmodule State do
    @moduledoc false
    defstruct [:broker, :topology, :opts]
  end

  @doc false
  def start_link(broker, topology, opts) do
    GenServer.start_link(__MODULE__, [broker, topology, opts], name: __MODULE__)
  end

  @impl true
  def init([broker, topology, opts]) do
    Process.send(self(), :setup_topology, [])

    {:ok, %State{broker: broker, topology: topology, opts: opts}}
  end

  @impl true
  def handle_info(:setup_topology, %State{broker: broker, topology: topology, opts: opts} = state) do
    sqs().setup_topology(topology, opts)
    meta().activate_pollers(broker)

    {:stop, :normal, state}
  end
end
