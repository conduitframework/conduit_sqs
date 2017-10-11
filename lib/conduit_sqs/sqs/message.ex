defmodule ConduitSQS.SQS.Message do
  alias Conduit.Message
  import Conduit.Message

  def to_conduit_messages(%{request_id: request_id, messages: messages}, queue) do
    Enum.map(messages, &to_conduit_message(&1, queue, request_id))
  end

#   %{messages: [%{attributes: %{"approximate_first_receive_timestamp" => 1507763212356,
#   "approximate_receive_count" => 1,
#   "sender_id" => "AIDAI4CGXQJHPWYLAP2OK",
#   "sent_timestamp" => 1507763179407}, body: "hi",
# md5_of_body: "49f68a5c8493ec2c0bf489821c21fc3b",
# message_attributes: %{"attempts" => %{binary_value: "",
#     data_type: "Number", name: "attempts", string_value: "1",
#     value: 1},
#   "correlation_id" => %{binary_value: "", data_type: "String",
#     name: "correlation_id", string_value: "1", value: "1"},
#   "created_by" => %{binary_value: "", data_type: "String",
#     name: "created_by", string_value: "test", value: "test"},
#   "ignore" => %{binary_value: "", data_type: "Number.boolean",
#     name: "ignore", string_value: "1", value: 1}},
# message_id: "73a1f59e-4404-4e65-949a-898ff15a115f",
# receipt_handle: "AQEB4BiZXKTjxdeQk7+wqec6+YkhezHKhYLKOCZG6yluPBsi1bhlqGv/i2AAmHETKELmAvwlgJE6j7DJwaarlFQiG0uVv82d2b/GyVkqOwE82NFJNgB+CEmT/1ESBocQYO2SyUmWk6XLOOiyZqgsJ/7hzIeNnbrMn/OWaX325M1BPu4K3bgHGhognKXAjtpA9yiyKsGp2kp2noeXj6nFMMp6r/eZbSORJOZRuVvbMkrd/AyjZxF2rVaVNtvR9NJreq1tyE/o6hwBzE8BPQTPcPQAx+EyDP0SFlHc2F0Aqo9m9zp6LKIcN6aKe874Re1rmDXijJrdBnkBQYzbrGCXf15nSwBmJ4Dv8/o24VyqFNkIpcDw61tAsb1nTFW26ccK7yFW"}],
# request_id: "4c62b197-cedf-5e87-9813-e3cf689311b3"}

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

  # %{"approximate_first_receive_timestamp" => 1507763212356,
  #   "approximate_receive_count" => 1,
  #   "sender_id" => "AIDAI4CGXQJHPWYLAP2OK",
  #   "sent_timestamp" => 1507763179407}
  defp put_attributes(message, attrs) do
    Enum.reduce(attrs, message, fn {name, value}, message ->
      put_header(message, name, value)
    end)
  end

  # %{"attempts" => %{binary_value: "",
  #     data_type: "Number", name: "attempts", string_value: "1",
  #     value: 1},
  #   "correlation_id" => %{binary_value: "", data_type: "String",
  #     name: "correlation_id", string_value: "1", value: "1"},
  #   "created_by" => %{binary_value: "", data_type: "String",
  #     name: "created_by", string_value: "test", value: "test"},
  #   "ignore" => %{binary_value: "", data_type: "Number.boolean",
  #     name: "ignore", string_value: "1", value: 1}}
  defp put_message_attributes(message, attrs) do
    Enum.reduce(attrs, message, fn {name, attr}, message ->
      put_message_attribute(message, name, attr)
    end)
  end

  # user_id - An ID representing which user the message pertains to.
  # correlation_id - An ID for a chain of messages, where the current message is one in that chain.
  # message_id - A unique ID for this message.
  # content_type - The media type of the message body.
  # content_encoding - The encoding of the message body.
  # created_by - The name of the app that created the message.
  # created_at - A timestamp or epoch representing when the message was created.
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
