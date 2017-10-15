defmodule ConduitSQS.SetupTest do
  use ExUnit.Case, async: true
  import Injex.Test
  alias ConduitSQS.Setup

  defmodule SQS do
    def setup_topology(topology, opts) do
      send(self(), {:setup_topology, topology, opts})
    end
  end

  defmodule Meta do
    def activate_pollers(broker) do
      send(self(), {:activate_pollers, broker})
    end
  end

  describe "init/1" do
    test "sends self message to setup topology" do
      assert Setup.init([Broker, [], []]) == {:ok, %Setup.State{broker: Broker, topology: [], opts: []}}

      assert_received(:setup_topology)
    end
  end

  describe "handle_info/2" do
    test "sets up topology and stops" do
      override(Setup, sqs: SQS, meta: Meta) do
        state = %Setup.State{broker: Broker, topology: [], opts: []}
        assert Setup.handle_info(:setup_topology, state) == {:stop, :normal, state}

        assert_received({:setup_topology, [], []})
        assert_received({:activate_pollers, Broker})
      end
    end
  end
end
