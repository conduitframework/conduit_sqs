defmodule ConduitSQS.WorkerTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.Worker
  alias Conduit.Message
  import Injex.Test

  describe "init/1" do
    test "sets itself as a consumer, sets up state, and subscribes to the pollers" do
      expected_return = {
        :consumer,
        %Worker.State{
          broker: Broker,
          name: :name,
          adapter_opts: []
        },
        subscribe_to: [
          {{:via, Registry, {Broker.Adapter.Registry, {Broker.Adapter.Poller, :name}}},
           [
             max_demand: 1000,
             min_demand: 500
           ]}
        ]
      }

      assert Worker.init([Broker, :name, []]) == expected_return
    end
  end

  describe "handle_events/3" do
    defmodule MessageProcessor do
      def process(broker, name, messages, opts) do
        send(self(), {:process, broker, name, messages, opts})
      end
    end

    test "processes the messages" do
      override Worker, message_processor: MessageProcessor do
        messages = [%Message{}]
        state = %Worker.State{broker: Broker, name: :name, adapter_opts: []}
        assert {:noreply, [], state, :hibernate} == Worker.handle_events(messages, self(), state)

        assert_received {:process, Broker, :name, ^messages, []}
      end
    end
  end
end
