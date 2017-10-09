defmodule ConduitSQSTest do
  use ExUnit.Case
  doctest ConduitSQS

  defmodule Broker do
    use Conduit.Broker, otp_app: :conduit_sqs
  end

  defmodule Subscriber do
    use Conduit.Subscriber

    def perform(message, _opts) do
      message
    end
  end

  describe "init/1" do
    @tag :capture_log
    test "return the child specifications for the options passed" do
      broker = Broker
      subscribers = %{
        conduitsqs_test: {Subscriber, [from: ["conduitsqs-test"]]}
      }
      topology = [
        {:queue, "conduitsqs-test", []}
      ]
      {:ok, {adapter_opts, child_specs}} = ConduitSQS.init([broker, topology, subscribers, []])

      # {strategy, max_restarts, max_seconds}
      assert adapter_opts == {:one_for_one, 3, 5}
      assert child_specs == [
        {ConduitSQS.Setup, {ConduitSQS.Setup, :start_link, [[{:queue, "conduitsqs-test", []}], []]},
          :transient, 5000, :worker, [ConduitSQS.Setup]},
        {ConduitSQS.PollerSupervisor, {ConduitSQS.PollerSupervisor, :start_link, [[]]},
          :permanent, :infinity, :supervisor, [ConduitSQS.PollerSupervisor]},
        {ConduitSQS.WorkerGroupSupervisor, {ConduitSQS.WorkerGroupSupervisor, :start_link, [[]]},
          :permanent, :infinity, :supervisor, [ConduitSQS.WorkerGroupSupervisor]}
      ]
    end
  end
end
