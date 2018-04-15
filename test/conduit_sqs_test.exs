defmodule ConduitSQSTest do
  use ExUnit.Case
  doctest ConduitSQS

  describe "init/1" do
    @tag :capture_log
    test "return the child specifications for the options passed" do
      broker = Broker

      subscribers = [
        conduitsqs_test: [from: "conduitsqs-test"]
      ]

      topology = [
        {:queue, "conduitsqs-test", []}
      ]

      {:ok, {adapter_opts, child_specs}} = ConduitSQS.init([broker, topology, subscribers, []])

      # {strategy, max_restarts, max_seconds}
      assert adapter_opts == %{intensity: 3, period: 5, strategy: :one_for_one}

      assert [
               registry_supervisor,
               setup_worker,
               poller_supervisor,
               worker_group_supervisor
             ] = child_specs

      assert registry_supervisor == %{
               id: Broker.Adapter.Registry,
               start: {Registry, :start_link, [[keys: :unique, name: Broker.Adapter.Registry]]},
               type: :supervisor
             }

      assert setup_worker == %{
               id: Broker.Adapter.Setup,
               restart: :transient,
               start: {ConduitSQS.Setup, :start_link, [Broker, [{:queue, "conduitsqs-test", []}], []]},
               type: :worker
             }

      assert poller_supervisor == %{
               id: Broker.Adapter.PollerSupervisor,
               start:
                 {ConduitSQS.PollerSupervisor, :start_link, [Broker, [conduitsqs_test: [from: "conduitsqs-test"]], []]},
               type: :supervisor
             }

      assert worker_group_supervisor == %{
               id: Broker.Adapter.WorkerGroupSupervisor,
               start:
                 {ConduitSQS.WorkerGroupSupervisor, :start_link,
                  [Broker, [conduitsqs_test: [from: "conduitsqs-test"]], []]},
               type: :supervisor
             }
    end
  end
end
