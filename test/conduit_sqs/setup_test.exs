defmodule ConduitSQS.SetupTest do
  use ExUnit.Case, async: true
  import Injex.Test
  alias ConduitSQS.Setup

  defmodule SQS do
    def setup_topology(topology, opts) do
      send(self(), {:setup_topology, topology, opts})
    end
  end

  describe "init/1" do
    test "sends self message to setup topology" do
      assert Setup.init([[], []]) == {:ok, %Setup.State{topology: [], opts: []}}

      assert_received(:setup_topology)
    end
  end

  describe "handle_info/2" do
    test "sets up topology and stops" do
      override(Setup, sqs: SQS) do
        state = %Setup.State{topology: [], opts: []}
        assert Setup.handle_info(:setup_topology, state) == {:stop, "topology setup", state}

        assert_received({:setup_topology, [], []})
      end
    end
  end
end
