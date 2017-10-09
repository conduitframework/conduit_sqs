defmodule ConduitSQS.SQSTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConduitSQS.SQS

  setup do
    opts = Application.get_env(:conduit, ConduitSQSTest)
    {:ok, %{opts: opts}}
  end

  describe "setup_topology/2" do
    test "creates no queues when topology is empty" do
      assert SQS.setup_topology([], []) == []
    end

    @tag :capture_log
    test "creates queues defined in topology", %{opts: opts} do
      topology = [{:queue, "conduit-test", [receive_message_wait_time_seconds: 0]}]

      use_cassette "setup_topology" do
        assert [%{
          queue_url: "https://sqs.us-east-1.amazonaws.com/974419985843/conduit-test",
          request_id: _
        }] = SQS.setup_topology(topology, opts)
      end
    end
  end
end
