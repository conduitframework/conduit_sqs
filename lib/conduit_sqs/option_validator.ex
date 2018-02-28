defmodule ConduitSQS.OptionValidator do
  @moduledoc """
  Validates that options passed in the broker are valid upon startup
  """
  require Logger

  defmodule OptionError do
    defexception [:message]
  end

  @type topology :: Conduit.Adapter.topology()
  @type subscribers :: Conduit.Adapter.subscribers()
  @type adapter_opts :: Keyword.t()

  @spec validate!(topology, subscribers, adapter_opts) :: true | no_return
  def validate!(topology, subscribers, adapter_opts) do
    validate_topology!(topology)
    validate_subscribers!(subscribers)
    validate_adapter_opts!(adapter_opts)

    true
  end

  defp validate_topology!(topology) do
    Enum.each(topology, fn
      {:queue, queue, opts} ->
        unless is_binary(queue) do
          raise OptionError, "Invalid queue name #{inspect(queue)}"
        end

        validate_create_queue_options(queue, opts)

      {:exchange, exchange, _} ->
        Logger.warn("ConduitSQS adapter does not support exchanges, but got exchange #{inspect(exchange)}")
    end)
  end

  @range_options %{
    maximum_message_size: 1024..262_144,
    message_retention_period: 60..1_209_600,
    delay_seconds: 0..900,
    receive_message_wait_time_seconds: 0..20
  }
  for {option, range} <- @range_options, range = Macro.escape(range) do
    defp validate_create_queue_options(queue, [{unquote(option) = option, value} | _])
         when value not in unquote(range) do
      raise_create_queue_option_error(queue, option, "be in #{inspect(unquote(range))}", value)
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
    raise OptionError,
          "Expected #{inspect(option_name)} for queue #{inspect(queue)} to #{expectation}, but got #{inspect(value)}"
  end

  defp validate_subscribers!(subscribers) do
    Enum.each(subscribers, fn
      {name, opts} when is_atom(name) ->
        validate_from(name, opts)
        validate_subscriber_options(name, opts)

      {name, _} ->
        raise OptionError, "Expected subscribe name to be an atom, but got #{inspect(name)}"
    end)
  end

  defp validate_from(name, opts) do
    case Keyword.fetch(opts, :from) do
      {:ok, from} when is_binary(from) ->
        true

      {:ok, from} ->
        raise OptionError, "Expected :from for subscription #{inspect(name)} to be a binary, but got #{inspect(from)}"

      :error ->
        raise OptionError, "Expected :from for subscription #{inspect(name)} to be a binary, but got none"
    end
  end

  for option <- [:attribute_names, :message_attribute_names] do
    defp validate_subscriber_options(name, [{unquote(option) = option, names} | _])
         when names != :all and not is_list(names) do
      raise OptionError,
            "Expected #{inspect(option)} for subscription #{inspect(name)} to be :all or a list of valid attribute names"
    end
  end

  option_ranges = [
    max_number_of_messages: 1..10,
    visibility_timeout: 0..43_200,
    wait_time_seconds: 0..20
  ]

  for {option, range} <- option_ranges, range = Macro.escape(range) do
    defp validate_subscriber_options(name, [{unquote(option), num} | _])
         when num not in unquote(range) do
      raise OptionError,
            "Expected #{unquote(option)} for subscription #{inspect(name)} to be in range #{inspect(unquote(range))}, \
            but got #{inspect(num)}"
    end
  end

  defp validate_subscriber_options(name, [{:worker_pool_size, num} | _])
       when (is_number(num) and num <= 0) or not is_number(num) do
    raise OptionError,
          "Expected :worker_pool_size for subscription #{inspect(name)} to be greater than 0, but got #{inspect(num)}"
  end

  defp validate_subscriber_options(name, [_ | rest]) do
    validate_subscriber_options(name, rest)
  end

  defp validate_subscriber_options(_name, []) do
    true
  end

  defp validate_adapter_opts!([{:worker_pool_size, num} | _])
       when (is_number(num) and num <= 0) or not is_number(num) do
    raise OptionError, "Expected :worker_pool_size for adapter option to be greater than 0, but got #{inspect(num)}"
  end

  defp validate_adapter_opts!([_ | rest]) do
    validate_adapter_opts!(rest)
  end

  defp validate_adapter_opts!([]), do: true
end
