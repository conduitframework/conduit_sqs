defmodule ConduitSQS.MetaTest do
  use ExUnit.Case, async: true
  alias ConduitSQS.Meta

  defmodule Broker do
  end

  test "controls pollers being active" do
    Meta.create(Broker)

    refute Meta.pollers_active?(Broker)

    Meta.activate_pollers(Broker)

    assert Meta.pollers_active?(Broker)
  end
end
