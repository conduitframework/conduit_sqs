defmodule ConduitSQSIntegrationTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Conduit.Message

  defmodule Subscriber do
    use Conduit.Subscriber

    def process(message, _) do
      send(ConduitSQSIntegrationTest, {:process, message})
      message
    end
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :conduit_sqs

    configure do
      queue "subscription"
    end

    pipeline :out_tracking do
      plug Conduit.Plug.LogOutgoing
    end

    pipeline :in_tracking do
      plug Conduit.Plug.LogIncoming
    end

    outgoing do
      pipe_through [:out_tracking]

      publish :sub, to: "subscription"
    end

    incoming ConduitSQSIntegrationTest do
      pipe_through [:in_tracking]

      subscribe :sub, :"Elixir.Subscriber", from: "subscription"
    end
  end

  @tag :capture_log
  @tag :integration_test
  test "creates queue, publishes messages, and consumes them" do
    Process.register(self(), __MODULE__)
    {:ok, _pid} = Broker.start_link()

    message = Message.put_body(%Message{}, "hi")

    Broker.publish(:sub, message)

    assert_receive {:process, consumed_message}, 1000

    assert consumed_message.body == "hi"
  end
end
