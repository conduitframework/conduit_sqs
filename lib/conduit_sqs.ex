defmodule ConduitSQS do
  use Conduit.Adapter
  use Supervisor
  require Logger
  alias ConduitSQS.SQS

  def start_link(broker, topology, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts], name: __MODULE__)
  end

  def init([broker, topology, subscribers, opts]) do
    Logger.info("SQS Adapter started!")
    import Supervisor.Spec

    children = [
      worker(ConduitSQS.Setup, [topology, opts], restart: :transient),
      supervisor(ConduitSQS.PollerSupervisor, [subscribers, opts]),
      supervisor(ConduitSQS.WorkerGroupSupervisor, [broker, subscribers, opts])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def publish(message, config, opts) do
    SQS.publish(message, config, opts)
  end
end
