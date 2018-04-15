defmodule ConduitSQS.WorkerGroupSupervisorTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.WorkerGroupSupervisor

  describe "init/1" do
    test "returns child specs for each subscriber" do
      subscribers = %{
        test: [],
        test2: []
      }

      assert {:ok, {sup_opts, child_specs}} = WorkerGroupSupervisor.init([Broker, subscribers, []])

      assert sup_opts == %{intensity: 3, period: 5, strategy: :one_for_one}

      expected_child_specs = [
        %{
          id: {Broker.Adapter.WorkerSupervisor, :test},
          start: {ConduitSQS.WorkerSupervisor, :start_link, [Broker, :test, [], []]},
          type: :supervisor
        },
        %{
          id: {Broker.Adapter.WorkerSupervisor, :test2},
          start: {ConduitSQS.WorkerSupervisor, :start_link, [Broker, :test2, [], []]},
          type: :supervisor
        }
      ]

      assert child_specs == expected_child_specs
    end
  end
end
