defmodule ConduitSQS.MessageProcessorTest do
  use ExUnit.Case, async: true
  import Injex.Test
  import Conduit.Message
  alias ConduitSQS.MessageProcessor
  alias Conduit.Message

  defmodule MyApp.Acker do
    use Conduit.Subscriber

    def process(message, _) do
      message
    end
  end

  defmodule MyApp.Nacker do
    use Conduit.Subscriber

    def process(message, _) do
      nack(message)
    end
  end

  defmodule MyApp.Error do
    use Conduit.Subscriber

    def process(_, _) do
      raise "failure"
    end
  end

  defmodule Broker do
    use Conduit.Broker, otp_app: :my_app

    incoming ConduitSQS.MessageProcessorTest.MyApp do
      subscribe :acker, Acker, from: "ackable"
      subscribe :nacker, Nacker, from: "nackable"
      subscribe :error, Error, from: "errorable"
    end
  end

  defmodule SQS do
    def ack_messages(results, opts) do
      send(self(), {:ack_messages, results, opts})
    end
  end

  describe "process/4" do
    test "when processing produces an ack, it produces a tuple with ack" do
      override MessageProcessor, sqs: SQS do
        message =
          %Message{}
          |> put_header("message_id", "123")
          |> put_header("receipt_handle", "321")
          |> put_source("ackable")

        MessageProcessor.process(Broker, :acker, [message], [])

        assert_received {:ack_messages, [%{id: message_id, receipt_handle: receipt_handle}], []}
        assert get_header(message, "message_id") == message_id
        assert get_header(message, "receipt_handle") == receipt_handle
      end
    end

    test "when processing a message produces a nack, it does not ack that message" do
      override MessageProcessor, sqs: SQS do
        message =
          %Message{}
          |> put_source("nackable")

        MessageProcessor.process(Broker, :nacker, [message], [])

        assert_received {:ack_messages, [], []}
      end
    end

    test "when processing a message produces an error, it does not ack that message" do
      override MessageProcessor, sqs: SQS do
        message =
          %Message{}
          |> put_source("errorable")

        MessageProcessor.process(Broker, :error, [message], [])

        assert_received {:ack_messages, [], []}
      end
    end
  end
end
