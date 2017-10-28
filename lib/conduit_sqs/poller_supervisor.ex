defmodule ConduitSQS.PollerSupervisor do
  @moduledoc """
  Manages pollers
  """
  use Supervisor

  @doc false
  def start_link(broker, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, subscribers, opts], name: __MODULE__)
  end

  @doc false
  @impl true
  def init([broker, subscribers, opts]) do
    import Supervisor.Spec

    children =
      subscribers
      |> Enum.map(fn {name, opts} ->
        {name, opts[:from], opts}
      end)
      |> Enum.with_index()
      |> Enum.map(fn {{name, queue, subscriber_opts}, index} ->
        worker(ConduitSQS.Poller, [broker, name, queue, subscriber_opts, opts], id: {ConduitSQS.Poller, index})
      end)

    supervise(children, strategy: :one_for_one)
  end
end
