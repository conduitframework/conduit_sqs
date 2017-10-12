defmodule ConduitSQS.WorkerGroupSupervisor do
  use Supervisor

  def start_link(broker, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, subscribers, opts], name: __MODULE__)
  end

  def init([broker, subscribers, opts]) do
    import Supervisor.Spec

    children =
      subscribers
      |> Enum.map(fn {name, {subscriber, sub_opts}} ->
        supervisor(
          ConduitSQS.WorkerSupervisor,
          [broker, name, subscriber, sub_opts, opts],
          id: {ConduitSQS.WorkerSupervisor, subscriber}
        )
      end)

    supervise(children, strategy: :one_for_one)
  end
end
