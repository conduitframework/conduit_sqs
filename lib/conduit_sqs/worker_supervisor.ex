defmodule ConduitSQS.WorkerSupervisor do
  @moduledoc """
  Manages workers for a specific queue
  """
  use Supervisor

  def child_spec([broker, name, _, _] = args) do
    %{
      id: name(broker, name),
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  @doc false
  def start_link(broker, name, sub_opts, opts) do
    Supervisor.start_link(__MODULE__, [broker, name, sub_opts, opts])
  end

  @doc false
  @impl true
  def init([broker, name, sub_opts, opts]) do
    opts = Keyword.merge(opts, sub_opts)
    worker_pool_size = Keyword.get(opts, :worker_pool_size, 5)

    children =
      1..worker_pool_size
      |> Enum.map(fn num ->
        {ConduitSQS.Worker, [broker, name, num, opts]}
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def name(broker, name) do
    {Module.concat(broker, Adapter.WorkerSupervisor), name}
  end
end
