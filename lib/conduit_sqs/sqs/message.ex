defmodule ConduitSQS.SQS.Message do
  @moduledoc """
  Converts a batch of SQS messages to Conduit messages
  """
  alias Conduit.Message
  import Conduit.Message

  @doc false
  def to_conduit_messages(%{request_id: request_id, messages: messages}, queue) do
    Enum.map(messages, &to_conduit_message(&1, queue, request_id))
  end

  defp to_conduit_message(%{
    body: body,
    attributes: attrs,
    md5_of_body: md5,
    message_attributes: msg_attrs,
    message_id: message_id,
    receipt_handle: handle
  },
  queue,
  request_id) do
    %Message{}
    |> put_source(queue)
    |> put_body(body)
    |> put_header("request_id", request_id)
    |> put_header("md5_of_body", md5)
    |> put_header("receipt_handle", handle)
    |> put_header("message_id", message_id)
    |> put_attributes(attrs)
    |> put_message_attributes(msg_attrs)
  end

  defp put_attributes(message, attrs) do
    Enum.reduce(attrs, message, fn {name, value}, message ->
      put_header(message, name, value)
    end)
  end

  defp put_message_attributes(message, attrs) do
    Enum.reduce(attrs, message, fn {name, attr}, message ->
      put_message_attribute(message, name, attr)
    end)
  end

  defp put_message_attribute(message, name, %{value: value})
  when name in ["user_id", "correlation_id", "message_id", "content_type", "content_encoding", "created_by", "created_at"] do
    Map.put(message, String.to_existing_atom(name), value)
  end
  defp put_message_attribute(message, name, %{value: value, data_type: "Number.boolean"}) do
    put_header(message, name, if(value == 1, do: true, else: false))
  end
  defp put_message_attribute(message, name, %{value: value}) do
    put_header(message, name, value)
  end
end
