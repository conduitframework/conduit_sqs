defmodule ConduitSQS.WorkerSupervisorTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.WorkerSupervisor

  describe "init/1" do
    test "returns child specs equal to worker pool size" do
      assert {:ok, {sup_opts, child_specs}} = WorkerSupervisor.init([Broker, :test, [], [worker_pool_size: 2]])

      assert sup_opts == %{intensity: 3, period: 5, strategy: :one_for_one}

      expected_child_specs = [
        %{
          id: {Broker.Adapter.Worker, :test, 1},
          start: {ConduitSQS.Worker, :start_link, [Broker, :test, 1, [worker_pool_size: 2]]},
          type: :worker
        },
        %{
          id: {Broker.Adapter.Worker, :test, 2},
          start: {ConduitSQS.Worker, :start_link, [Broker, :test, 2, [worker_pool_size: 2]]},
          type: :worker
        }
      ]

      assert child_specs == expected_child_specs
    end
  end
end
