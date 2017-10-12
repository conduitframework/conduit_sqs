defmodule ConduitSQS.WorkerSupervisor do
  use Supervisor

  def start_link(broker, name, subscriber, sub_opts, opts) do
    Supervisor.start_link(__MODULE__, [broker, name, subscriber, sub_opts, opts], name: __MODULE__)
  end

  def init([broker, name, subscriber, sub_opts, opts] = args) do
    import Supervisor.Spec

    worker_pool_size = Keyword.get(sub_opts, :worker_pool_size, Keyword.get(opts, :worker_pool_size, 5))

    children =
      1..worker_pool_size
      |> Enum.map(fn num ->
        worker(ConduitSQS.Worker, args, id: {ConduitSQS.Worker, num})
      end)

    supervise(children, strategy: :one_for_one)
  end
end
