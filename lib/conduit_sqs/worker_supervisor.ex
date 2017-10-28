defmodule ConduitSQS.WorkerSupervisor do
  @moduledoc """
  Manages workers for a specific queue
  """
  use Supervisor

  @doc false
  def start_link(broker, name, sub_opts, opts) do
    Supervisor.start_link(__MODULE__, [broker, name, sub_opts, opts], name: __MODULE__)
  end

  @doc false
  @impl true
  def init([broker, name, sub_opts, opts]) do
    import Supervisor.Spec

    worker_pool_size = Keyword.get(sub_opts, :worker_pool_size, Keyword.get(opts, :worker_pool_size, 5))

    children =
      1..worker_pool_size
      |> Enum.map(fn num ->
        worker(ConduitSQS.Worker, [broker, name, num, opts], id: {ConduitSQS.Worker, num})
      end)

    supervise(children, strategy: :one_for_one)
  end
end
