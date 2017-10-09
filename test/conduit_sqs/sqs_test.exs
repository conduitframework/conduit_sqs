defmodule ConduitSQS.SQSTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConduitSQS.SQS
  alias Conduit.Message
  import Conduit.Message

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

  describe "publish/3" do
    test "publish the message with all of its attributes and headers", %{opts: config} do
      message =
        %Message{}
        |> put_header("attempts", 1)
        |> put_header("ignore", true)
        |> put_created_by("test")
        |> put_correlation_id("1")
        |> put_body("hi")
        |> put_destination("conduit-test")

      use_cassette "publish" do
        assert %{
          md5_of_message_attributes: "b005563a2fd67fbf2895879f0a08c2b5",
          md5_of_message_body: "49f68a5c8493ec2c0bf489821c21fc3b",
          message_id: _,
          request_id: _
        } = SQS.publish(message, config, [])
      end
    end
  end
end
