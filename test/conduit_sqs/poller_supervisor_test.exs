defmodule ConduitSQS.PollerSupervisorTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.PollerSupervisor

  describe "init/1" do
    @args [
      Broker,
      [
        conduitsqs_test: [from: "conduitsqs-test"],
        conduitsqs_test2: [from: "conduitsqs-test2"]
      ],
      []
    ]
    test "returns child specs for each queue" do
      assert {:ok, {sup_opts, child_specs}} = PollerSupervisor.init(@args)

      assert sup_opts == %{intensity: 3, period: 5, strategy: :one_for_one}

      expected_child_specs = [
        %{
          id: {Broker.Adapter.Poller, :conduitsqs_test},
          start:
            {ConduitSQS.Poller, :start_link,
             [Broker, :conduitsqs_test, "conduitsqs-test", [from: "conduitsqs-test"], []]},
          type: :worker
        },
        %{
          id: {Broker.Adapter.Poller, :conduitsqs_test2},
          start:
            {ConduitSQS.Poller, :start_link,
             [Broker, :conduitsqs_test2, "conduitsqs-test2", [from: "conduitsqs-test2"], []]},
          type: :worker
        }
      ]

      assert child_specs == expected_child_specs
    end
  end
end
