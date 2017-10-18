defmodule ConduitSQS.OptionValidator do
  require Logger

  defmodule OptionError do
    defexception [:message]
  end

  # topology = [{:queue, "conduit-test", [receive_message_wait_time_seconds: 0]}]
  def validate_topology!(topology) do
    Enum.each(topology, fn
      {:queue, queue, opts} ->
        unless is_binary(queue) do
          raise OptionError, "Invalid queue name #{inspect queue}"
        end

        validate_create_queue_options(queue, opts)
      {:exchange, exchange, _} ->
        Logger.warn("ConduitSQS adapter does not support exchanges, but got exchange #{inspect exchange}")
    end)
  end

  @range_options %{
    maximum_message_size: 1024..262144,
    message_retention_period: 60..1209600,
    delay_seconds: 0..900,
    receive_message_wait_time_seconds: 0..20
  }
  for {option, range} <- @range_options, range = Macro.escape(range) do
    defp validate_create_queue_options(queue, [{unquote(option) = option, value} | _])
    when value not in unquote(range) do
      raise_create_queue_option_error(queue, option, "be in #{inspect unquote(range)}", value)
    end
  end

  @binary_options ~w(policy redrive_policy)a
  for option <- @binary_options do
    defp validate_create_queue_options(queue, [{unquote(option) = option, value} | _])
    when not is_binary(value) do
      raise_create_queue_option_error(queue, option, "be a string", value)
    end
  end

  @boolean_options ~w(fifo_queue content_based_deduplication)a
  for option <- @boolean_options do
    defp validate_create_queue_options(queue, [{unquote(option) = option, value} | _])
    when value not in [nil, false, true] do
      raise_create_queue_option_error(queue, option, "be a boolean", value)
    end
  end

  defp validate_create_queue_options(queue, [_ | rest]) do
    validate_create_queue_options(queue, rest)
  end
  defp validate_create_queue_options(_, []), do: nil

  defp raise_create_queue_option_error(queue, option_name, expectation, value) do
    raise OptionError, "Expected #{inspect option_name} for queue #{inspect queue} to #{expectation}, but got #{inspect value}"
  end
end
