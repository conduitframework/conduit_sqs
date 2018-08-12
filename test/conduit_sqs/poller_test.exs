defmodule ConduitSQS.PollerTest do
  use ExUnit.Case, async: true
  import Injex.Test
  import ExUnit.CaptureLog
  alias ConduitSQS.Poller
  alias Conduit.Message

  describe "init/1" do
    test "sets itself as a producer and stores it's state" do
      queue = "conduitsqs-test"
      subscriber_opts = []
      adapter_opts = []

      assert Poller.init([Broker, queue, subscriber_opts, adapter_opts]) == {
               :producer,
               %Poller.State{
                 broker: Broker,
                 queue: queue,
                 subscriber_opts: subscriber_opts,
                 adapter_opts: adapter_opts
               },
               [demand: :accumulate]
             }

      assert_received :check_active
    end
  end

  describe "handle_demand/2" do
    test "when there is already demand, it adds the new demand to the current demand" do
      state = %Poller.State{demand: 1}

      assert Poller.handle_demand(2, state) == {:noreply, [], %Poller.State{demand: 3}}
      refute_received :get_messages
    end

    test "when there is no demand, it sets the new demand and schedules the poller" do
      state = %Poller.State{demand: 0}

      assert Poller.handle_demand(3, state) == {:noreply, [], %Poller.State{demand: 3}}
      assert_received :get_messages
    end
  end

  describe "handle_info/2 :get_messages" do
    defmodule SQSEqual do
      def get_messages(_queue, fetch_amount, _subscriber_opts, _adapter_opts) do
        Enum.map(1..fetch_amount, fn _ -> %Message{} end)
      end
    end

    test "when all demand is handled, it produces messages and updates demand" do
      override Poller, sqs: SQSEqual do
        state = %Poller.State{
          queue: "conduitsqs-test",
          subscriber_opts: [max_number_of_messages: 5],
          adapter_opts: [],
          demand: 5
        }

        assert Poller.handle_info(:get_messages, state) == {
                 :noreply,
                 [%Message{}, %Message{}, %Message{}, %Message{}, %Message{}],
                 %Poller.State{
                   queue: "conduitsqs-test",
                   subscriber_opts: [max_number_of_messages: 5],
                   adapter_opts: [],
                   demand: 0
                 },
                 :hibernate
               }

        refute_received :get_messages
      end
    end

    test "when demand equal to the fetch limit is handled, it produces messags, updates demand, and schedules immediately" do
      override Poller, sqs: SQSEqual do
        state = %Poller.State{
          queue: "conduitsqs-test",
          subscriber_opts: [max_number_of_messages: 5],
          adapter_opts: [],
          demand: 10
        }

        assert Poller.handle_info(:get_messages, state) == {
                 :noreply,
                 [%Message{}, %Message{}, %Message{}, %Message{}, %Message{}],
                 %Poller.State{
                   queue: "conduitsqs-test",
                   subscriber_opts: [max_number_of_messages: 5],
                   adapter_opts: [],
                   demand: 5
                 },
                 :hibernate
               }

        assert_received :get_messages
      end
    end

    defmodule SQSLess do
      def get_messages(_queue, fetch_amount, _subscriber_opts, _adapter_opts) do
        Enum.map(1..(fetch_amount - 2), fn _ -> %Message{} end)
      end
    end

    test "when demand less than the fetch limit is handled, it produces messags, updates demand, and schedules later" do
      override Poller, sqs: SQSLess do
        state = %Poller.State{
          queue: "conduitsqs-test",
          subscriber_opts: [max_number_of_messages: 5],
          adapter_opts: [],
          demand: 10
        }

        assert Poller.handle_info(:get_messages, state) == {
                 :noreply,
                 [%Message{}, %Message{}, %Message{}],
                 %Poller.State{
                   queue: "conduitsqs-test",
                   subscriber_opts: [max_number_of_messages: 5],
                   adapter_opts: [],
                   demand: 7
                 },
                 :hibernate
               }

        assert_receive :get_messages, 300
      end
    end
  end

  describe "handle_info/2 :check_active" do
    defmodule MetaActive do
      def pollers_active?(_broker) do
        true
      end
    end

    test "when pollers should be active" do
      override Poller, meta: MetaActive do
        result = assert capture_log(fn ->
          Poller.handle_info(:check_active, %Poller.State{queue: "foo"})
        end)

        assert result =~ "Starting poller for queue \"foo\" in \"default region\""
        assert_received {:"$gen_cast", {:"$demand", :forward}}
      end
    end

    defmodule MetaInactive do
      def pollers_active?(_broker) do
        false
      end
    end

    test "when pollers should not be active" do
      override Poller, meta: MetaInactive do
        Poller.handle_info(:check_active, %Poller.State{})

        assert_receive :check_active, 40
      end
    end
  end
end
