defmodule ConduitSQS.SQS.Options do
  import Conduit.Message

  def from(message, opts) do
    [{:message_attributes, get_message_attributes(message)} | opts]
    |> put_present_option(:message_deduplication_id, get_header(message, "deduplication_id"))
    |> put_present_option(:group_id, get_header(message, "group_id"))
  end

  @attributes ~w(
    content_type
    content_encoding
    created_by
    created_at
    message_id
    correlation_id
    user_id
  )a
  defp get_message_attributes(message) do
    header_attributes =
      message.headers
      |> Enum.filter(fn
        {_, nil} -> false
        _ -> true
      end)
      |> Enum.map(fn {name, value} ->
        build_sqs_attribute(name, value)
      end)

    attributes =
      @attributes
      |> Enum.filter(&Map.get(message, &1))
      |> Enum.map(fn attribute ->
        attribute
        |> Atom.to_string()
        |> build_sqs_attribute(Map.get(message, attribute))
      end)

    header_attributes ++ attributes
  end

  defp build_sqs_attribute(name, value) when is_boolean(value) do
    build_sqs_attribute(name, :number, "boolean", if(value, do: 1, else: 0))
  end
  defp build_sqs_attribute(name, value) when is_number(value) do
    build_sqs_attribute(name, :number, nil, value)
  end
  defp build_sqs_attribute(name, value) when is_binary(value) do
    if String.printable?(value) do
      build_sqs_attribute(name, :string, nil, value)
    else
      build_sqs_attribute(name, :binary, nil, value)
    end
  end

  defp build_sqs_attribute(name, type, nil, value) do
    %{name: name, data_type: type, value: value}
  end
  defp build_sqs_attribute(name, type, custom_type, value) do
    name
    |> build_sqs_attribute(type, nil, value)
    |> Map.put(:custom_type, custom_type)
  end

  defp put_present_option(options, _name, nil), do: options
  defp put_present_option(options, name, value) do
    Keyword.put(options, name, value)
  end
end
