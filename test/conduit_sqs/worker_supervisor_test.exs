defmodule ConduitSQS.WorkerSupervisorTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.WorkerSupervisor

  describe "init/1" do
    test "returns child specs equal to worker pool size" do
      assert {:ok, {sup_opts, child_specs}} = WorkerSupervisor.init([Broker, :test, [], [worker_pool_size: 2]])

      assert sup_opts == {:one_for_one, 3, 5}

      assert child_specs == [
        {{ConduitSQS.Worker, 1},
          {ConduitSQS.Worker, :start_link, [Broker, :test, 1, [worker_pool_size: 2]]},
          :permanent, 5000, :worker, [ConduitSQS.Worker]},
        {{ConduitSQS.Worker, 2},
          {ConduitSQS.Worker, :start_link, [Broker, :test, 2, [worker_pool_size: 2]]},
          :permanent, 5000, :worker, [ConduitSQS.Worker]}
      ]
    end
  end
end
