defmodule ConduitSQS.OptionValidatorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias ConduitSQS.OptionValidator
  alias ConduitSQS.OptionValidator.OptionError

  describe "validate!/1" do
    test "warn when exchange is specified" do
      topology = [{:exchange, "blah", []}]

      assert capture_log(fn ->
               OptionValidator.validate!(topology, [], [])
             end) =~ "ConduitSQS adapter does not support exchanges, but got"
    end

    test "raise when queue name is not a binary" do
      topology = [{:queue, :blah, []}]

      assert_raise OptionError, "Invalid queue name :blah", fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when maximum_message_size option is outside range" do
      first..last = 1024..262_144

      topology = [{:queue, "blah", [{:maximum_message_size, first - 1}]}]
      error_message = "Expected :maximum_message_size for queue \"blah\" to be in 1024..262144, but got 1023"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end

      topology = [{:queue, "blah", [{:maximum_message_size, last + 1}]}]
      error_message = "Expected :maximum_message_size for queue \"blah\" to be in 1024..262144, but got 262145"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when message_retention_period option is outside range" do
      first..last = 60..1_209_600

      topology = [{:queue, "blah", [{:message_retention_period, first - 1}]}]
      error_message = "Expected :message_retention_period for queue \"blah\" to be in 60..1209600, but got 59"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end

      topology = [{:queue, "blah", [{:message_retention_period, last + 1}]}]
      error_message = "Expected :message_retention_period for queue \"blah\" to be in 60..1209600, but got 1209601"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when delay_seconds option is outside range" do
      first..last = 0..900

      topology = [{:queue, "blah", [{:delay_seconds, first - 1}]}]
      error_message = "Expected :delay_seconds for queue \"blah\" to be in 0..900, but got -1"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end

      topology = [{:queue, "blah", [{:delay_seconds, last + 1}]}]
      error_message = "Expected :delay_seconds for queue \"blah\" to be in 0..900, but got 901"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when receive_message_wait_time_seconds option is outside range" do
      first..last = 0..20

      topology = [{:queue, "blah", [{:receive_message_wait_time_seconds, first - 1}]}]
      error_message = "Expected :receive_message_wait_time_seconds for queue \"blah\" to be in 0..20, but got -1"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end

      topology = [{:queue, "blah", [{:receive_message_wait_time_seconds, last + 1}]}]
      error_message = "Expected :receive_message_wait_time_seconds for queue \"blah\" to be in 0..20, but got 21"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when policy option is not binary" do
      topology = [{:queue, "blah", [{:policy, :foo}]}]
      error_message = "Expected :policy for queue \"blah\" to be a string, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when redrive_policy option is not binary" do
      topology = [{:queue, "blah", [{:redrive_policy, :foo}]}]
      error_message = "Expected :redrive_policy for queue \"blah\" to be a string, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when fifo_queue option is not a boolean" do
      topology = [{:queue, "blah", [{:fifo_queue, :foo}]}]
      error_message = "Expected :fifo_queue for queue \"blah\" to be a boolean, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when content_based_deduplication option is not a boolean" do
      topology = [{:queue, "blah", [{:content_based_deduplication, :foo}]}]
      error_message = "Expected :content_based_deduplication for queue \"blah\" to be a boolean, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!(topology, [], [])
      end
    end

    test "raises when subscriber name is not an atom" do
      subscribers = [{"foo", []}]
      error_message = "Expected subscribe name to be an atom, but got \"foo\""

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end
    end

    test "raises when invalid from option is provided" do
      subscribers = [foo: []]
      error_message = "Expected :from for subscription :foo to be a binary, but got none"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end

      subscribers = [foo: [from: :queue]]
      error_message = "Expected :from for subscription :foo to be a binary, but got :queue"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end
    end

    test "raises when attribute_names option is invalid" do
      subscribers = [foo: [from: "x", attribute_names: :foo]]
      error_message = "Expected :attribute_names for subscription :foo to be :all or a list of valid attribute names"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end
    end

    test "raises when message_attribute_names option is invalid" do
      subscribers = [foo: [from: "x", message_attribute_names: :foo]]

      error_message =
        "Expected :message_attribute_names for subscription :foo to be :all or a list of valid attribute names"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end
    end

    test "raises when max_number_of_messages option is invalid" do
      subscribers = [foo: [from: "x", max_number_of_messages: :foo]]
      error_message = "Expected max_number_of_messages for subscription :foo to be in range 1..10, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end

      first..last = 1..10

      subscribers = [foo: [from: "x", max_number_of_messages: first - 1]]
      error_message = "Expected max_number_of_messages for subscription :foo to be in range 1..10, but got 0"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end

      subscribers = [foo: [from: "x", max_number_of_messages: last + 1]]
      error_message = "Expected max_number_of_messages for subscription :foo to be in range 1..10, but got 11"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end
    end

    test "raises when worker_pool_size option is invalid" do
      subscribers = [foo: [from: "x", worker_pool_size: :foo]]
      error_message = "Expected :worker_pool_size for subscription :foo to be greater than 0, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end

      subscribers = [foo: [from: "x", worker_pool_size: 0]]
      error_message = "Expected :worker_pool_size for subscription :foo to be greater than 0, but got 0"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], subscribers, [])
      end
    end

    test "raises when worker_pool_size adapter option is invalid" do
      adapter_opts = [worker_pool_size: :foo]
      error_message = "Expected :worker_pool_size for adapter option to be greater than 0, but got :foo"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], [], adapter_opts)
      end

      adapter_opts = [worker_pool_size: 0]
      error_message = "Expected :worker_pool_size for adapter option to be greater than 0, but got 0"

      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate!([], [], adapter_opts)
      end
    end
  end
end
