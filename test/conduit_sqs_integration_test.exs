defmodule ConduitSQSIntegrationTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Conduit.Message
  alias Conduit.Message

  defmodule Subscriber do
    use Conduit.Subscriber

    def process(message, _) do
      send(ConduitSQSIntegrationTest, {:process, message})
      message
    end
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :integration_test

    configure do
      queue "subscription"
    end

    outgoing do
      publish :sub, to: "subscription"
    end

    incoming ConduitSQSIntegrationTest do
      subscribe :sub, :"Elixir.Subscriber", from: "subscription"
    end
  end


  test "creates queue, publishes messages, and consumes them" do
    use_cassette "integration_test" do
      Process.register(self(), __MODULE__)
      {:ok, _pid} = Broker.start_link()

      message = put_body(%Message{}, "hi")

      Broker.publish(:sub, message)

      assert_receive {:process, consumed_message}

      assert consumed_message.body == "hi"
    end
  end
end
