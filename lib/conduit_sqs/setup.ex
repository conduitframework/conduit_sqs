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

  def child_spec([broker, _, _] = args) do
    %{
      id: name(broker),
      start: {__MODULE__, :start_link, args},
      restart: :transient,
      type: :worker
    }
  end

  @doc false
  def start_link(broker, topology, opts) do
    GenServer.start_link(__MODULE__, [broker, topology, opts], name: name(broker))
  end

  @impl true
  def init([broker, topology, opts]) do
    Process.send(self(), :setup_topology, [])

    {:ok, %State{broker: broker, topology: topology, opts: opts}}
  end

  def name(broker) do
    Module.concat(broker, Adapter.Setup)
  end

  @impl true
  def handle_info(:setup_topology, %State{broker: broker, topology: topology, opts: opts} = state) do
    sqs().setup_topology(topology, opts)
    meta().activate_pollers(broker)

    {:stop, :normal, state}
  end
end
