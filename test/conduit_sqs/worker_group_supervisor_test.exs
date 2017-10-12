defmodule ConduitSQS.WorkerGroupSupervisorTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.WorkerGroupSupervisor

  describe "init/1" do
    test "returns child specs for each subscriber" do
      subscribers = %{
        test: {Test, []},
        test2: {Test2, []}
      }
      assert {:ok, {sup_opts, child_specs}} = WorkerGroupSupervisor.init([Broker, subscribers, []])

      # {strategy, max_restarts, max_seconds}
      assert sup_opts == {:one_for_one, 3, 5}

      assert child_specs == [
        {{ConduitSQS.WorkerSupervisor, Test},
          {ConduitSQS.WorkerSupervisor, :start_link, [Broker, :test, Test, [], []]},
          :permanent, :infinity, :supervisor, [ConduitSQS.WorkerSupervisor]},
        {{ConduitSQS.WorkerSupervisor, Test2},
          {ConduitSQS.WorkerSupervisor, :start_link, [Broker, :test2, Test2, [], []]},
          :permanent, :infinity, :supervisor, [ConduitSQS.WorkerSupervisor]}
      ]
    end
  end
end
