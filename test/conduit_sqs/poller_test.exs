defmodule ConduitSQS.PollerTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.Poller

  describe "init/1" do
    test "sets itself as a producer and stores it's state" do
      queue = "conduitsqs-test"
      subscriber_opts = []
      adapter_opts = []

      assert Poller.init([queue, subscriber_opts, adapter_opts]) == {
        :producer,
        %Poller.State{queue: queue, subscriber_opts: subscriber_opts, adapter_opts: adapter_opts},
        [demand: :accumulate]
      }
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
end
