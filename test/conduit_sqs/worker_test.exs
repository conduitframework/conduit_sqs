defmodule ConduitSQS.WorkerTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.Worker
  alias Conduit.Message
  import Injex.Test

  describe "init/1" do
    test "sets itself as a consumer, sets up state, and subscribes to the pollers" do
      assert Worker.init([Broker, :name, []]) == {
        :consumer,
        %Worker.State{
          broker: Broker,
          name: :name,
          adapter_opts: []
        },
        subscribe_to: [{{:via, Registry, {Broker.Registry, {ConduitSQS.Poller, :name}}}, []}]
      }
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
        assert {:noreply, [], state} == Worker.handle_events(messages, self(), state)

        assert_received {:process, Broker, :name, ^messages, []}
      end
    end
  end
end
