defmodule ConduitSQS.MessageProcessor do
  @moduledoc """
  Processes a message batch and acks successful messages
  """
  import Injex
  alias Conduit.Message
  import Conduit.Message
  inject :sqs, ConduitSQS.SQS

  @doc """
  Processes messages and acks successful messages
  """
  @spec process(Conduit.Adapter.broker, atom, [Conduit.Message.t], Keyword.t) :: {:ok, term} | {:error, term}
  def process(broker, name, messages, opts) do
    messages
    |> Enum.map(&process_message(broker, name, &1))
    |> Enum.filter(fn
      {:ack, _} -> true
      {:nack, _} -> false
    end)
    |> Enum.map(fn {:ack, message} ->
      %{id: get_header(message, "message_id"), receipt_handle: get_header(message, "receipt_handle")}
    end)
    |> sqs().ack_messages(hd(messages).source, opts)
  end

  defp process_message(broker, name, message) do
    case broker.receives(name, message) do
      %Message{status: :ack} = msg ->
        {:ack, msg}
      %Message{status: :nack} = msg ->
        {:nack, msg}
    end
  rescue _ ->
    {:nack, message}
  end
end
