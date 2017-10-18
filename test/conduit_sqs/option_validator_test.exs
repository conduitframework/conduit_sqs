defmodule ConduitSQS.OptionValidatorTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias ConduitSQS.OptionValidator
  alias ConduitSQS.OptionValidator.OptionError

  describe "validate_topology!/1" do
    test "warn when exchange is specified" do
      topology = [{:exchange, "blah", []}]

      assert capture_log(fn ->
        OptionValidator.validate_topology!(topology)
      end) =~ "ConduitSQS adapter does not support exchanges, but got"
    end

    test "raise when queue name is not a binary" do
      topology = [{:queue, :blah, []}]

      assert_raise OptionError, "Invalid queue name :blah", fn ->
        OptionValidator.validate_topology!(topology)
      end
    end

    test "raises when range option is outside range" do
      first..last = 1024..262144

      topology = [{:queue, "blah", [{:maximum_message_size, first - 1}]}]
      error_message = "Expected :maximum_message_size for queue \"blah\" to be in 1024..262144, but got 1023"
      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate_topology!(topology)
      end

      topology = [{:queue, "blah", [{:maximum_message_size, last + 1}]}]
      error_message = "Expected :maximum_message_size for queue \"blah\" to be in 1024..262144, but got 262145"
      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate_topology!(topology)
      end
    end

    test "raises when binary option is not binary" do
      topology = [{:queue, "blah", [{:policy, :foo}]}]
      error_message = "Expected :policy for queue \"blah\" to be a string, but got :foo"
      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate_topology!(topology)
      end
    end

    test "raises when boolean option is not a boolean" do
      topology = [{:queue, "blah", [{:fifo_queue, :foo}]}]
      error_message = "Expected :fifo_queue for queue \"blah\" to be a boolean, but got :foo"
      assert_raise OptionError, error_message, fn ->
        OptionValidator.validate_topology!(topology)
      end
    end
  end
end
