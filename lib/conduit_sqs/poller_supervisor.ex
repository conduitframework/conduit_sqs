defmodule ConduitSQS.PollerSupervisor do
  use Supervisor

  def start_link(subscribers, opts) do
    Supervisor.start_link(__MODULE__, [subscribers, opts], name: __MODULE__)
  end

  def init([subscribers, opts]) do
    import Supervisor.Spec

    children = [
    ]

    supervise(children, strategy: :one_for_one)
  end
end
