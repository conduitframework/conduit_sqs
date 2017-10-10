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
end
