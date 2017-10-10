defmodule ConduitSQS.PollerSupervisor do
  use Supervisor

  def start_link(subscribers, opts) do
    Supervisor.start_link(__MODULE__, [subscribers, opts], name: __MODULE__)
  end

  # %{
  #   conduitsqs_test: {ConduitSQSTest.Subscriber, [from: ["conduitsqs-test"]]}
  # },
  def init([subscribers, opts]) do
    import Supervisor.Spec

    children =
      subscribers
      |> Enum.flat_map(fn {_name, {_subscriber, opts}} ->
        Enum.map(opts[:from], &{&1, opts})
      end)
      |> Enum.with_index()
      |> Enum.map(fn {{queue, opts}, index} ->
        worker(ConduitSQS.Poller, [queue, opts], id: {ConduitSQS.Poller, index})
      end)

    supervise(children, strategy: :one_for_one)
  end
end
