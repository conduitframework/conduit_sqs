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
      assert adapter_opts == {:one_for_one, 3, 5}

      assert [
        registry_supervisor,
        setup_worker,
        poller_supervisor,
        worker_group_supervisor
      ] = child_specs

      assert registry_supervisor == {
        Registry,
        {Registry, :start_link, [[keys: :unique, name: Broker.Registry]]},
        :permanent, :infinity, :supervisor, [Registry]
      }

      assert setup_worker == {
        ConduitSQS.Setup,
        {ConduitSQS.Setup, :start_link, [Broker, [{:queue, "conduitsqs-test", []}], []]},
        :transient, 5000, :worker, [ConduitSQS.Setup]
      }

      assert poller_supervisor == {
        ConduitSQS.PollerSupervisor,
        {ConduitSQS.PollerSupervisor, :start_link, [
          Broker,
          [conduitsqs_test: [from: "conduitsqs-test"]],
          []]
        },
        :permanent, :infinity, :supervisor, [ConduitSQS.PollerSupervisor]
      }

      assert worker_group_supervisor == {
        ConduitSQS.WorkerGroupSupervisor,
        {ConduitSQS.WorkerGroupSupervisor, :start_link, [
          Broker,
          [conduitsqs_test: [from: "conduitsqs-test"]],
          []
        ]},
        :permanent, :infinity, :supervisor, [ConduitSQS.WorkerGroupSupervisor]
      }
    end
  end
end
