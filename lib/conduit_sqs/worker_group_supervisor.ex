defmodule ConduitSQS.WorkerGroupSupervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, [opts], name: __MODULE__)
  end

  def init([opts]) do
    import Supervisor.Spec

    children = [

    ]

    supervise(children, strategy: :one_for_one)
  end
end
