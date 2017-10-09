defmodule ConduitSQS.Setup do
  use GenServer
  import Injex
  inject :sqs, ConduitSQS.SQS

  defmodule State do
    defstruct [:topology, :opts]
  end

  def start_link(topology, opts) do
    GenServer.start_link(__MODULE__, [topology, opts], name: __MODULE__)
  end

  def init([topology, opts]) do
    Process.send(self(), :setup_topology, [])

    {:ok, %State{topology: topology, opts: opts}}
  end

  def handle_info(:setup_topology, %State{topology: topology, opts: opts} = state) do
    sqs().setup_topology(topology, opts)

    {:stop, "topology setup", state}
  end
end
