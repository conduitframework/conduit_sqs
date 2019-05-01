# ConduitSQS

[![CircleCI](https://img.shields.io/circleci/project/github/conduitframework/conduit_sqs.svg?style=flat-square)](https://circleci.com/gh/conduitframework/conduit_sqs)
[![Coveralls](https://img.shields.io/coveralls/conduitframework/conduit_sqs.svg?style=flat-square)](https://coveralls.io/github/conduitframework/conduit_sqs)
[![Hex.pm](https://img.shields.io/hexpm/v/conduit_sqs.svg?style=flat-square)](https://hex.pm/packages/conduit_sqs)
[![Hex.pm](https://img.shields.io/hexpm/l/conduit_sqs.svg?style=flat-square)](https://github.com/conduitframework/conduit_sqs/blob/master/LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/dt/conduit_sqs.svg?style=flat-square)](https://hex.pm/packages/conduit_sqs)
[![Gratipay](https://img.shields.io/gratipay/blatyo.svg?style=flat-square)](https://gratipay.com/blatyo)

A [Conduit](https://github.com/conduitframework/conduit) adapter for SQS.

## Installation

The package can be installed by adding `conduit_sqs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:conduit_sqs, "~> 0.3.0"}]
end
```

## Configuring the Adapter

``` elixir
config :my_app, MyApp.Broker,
  adapter: ConduitSQS,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]
```

### Options

* `:adapter` - The adapter to use, should be `ConduitSQS`.
* `:access_key_id` - The AWS access key ID. [See what ExAWS supports](https://hexdocs.pm/ex_aws/ExAws.html#module-getting-started).
* `:secret_access_key` - The AWS secret access key. [See what ExAWS supports](https://hexdocs.pm/ex_aws/ExAws.html#module-getting-started).
* `:worker_pool_size` - The default number of worker for each subscription. Defaults to `5` when not specified. Can also be overridden on each `subscribe`.
* `:max_attempts` - How many times to retry publishing a message. Defaults to `10` when not specified. Can also be overriden on each `publish`.
* `:base_backoff_in_ms` - The base factor used to exponentially backoff when a request fails. Defaults to `10` when not specified. Can also be overriden on `queue`, `publish`, and `subscribe`.
* `:max_backoff_in_ms` - The maximum backoff when a request fails. Defaults to `10_000` when not specified. Can also be overriden on `queue`, `publish`, and `subscribe`.
* `:region` - The AWS region to use by default. Defaults to `"us-east-1"` when not specified. Can also be overriden on `queue`, `publish`, and `subscribe`.

## Configuring Queues

Inside the `configure` block of a broker, you can define queues that will be created at application
startup with the options you specify.

``` elixir
defmodule MyApp.Broker do
  configure do
    queue "my-queue"
    queue "my-other-queue.fifo", fifo_queue: true
  end
end
```

### Options

For creating a queue, ConduitSQS supports the same options that are specified in the SQS docs. See the
[SQS docs for creating a queue](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html)
to understand what each of the options mean. These options include:

* `:policy`
* `:visibility_timeout`
* `:maximum_message_size`
* `:message_retention_period`
* `:approximate_number_of_messages`
* `:approximate_number_of_messages_not_visible`
* `:created_timestamp`
* `:last_modified_timestamp`
* `:queue_arn`
* `:approximate_number_of_messages_delayed`
* `:delay_seconds`
* `:receive_message_wait_time_seconds`
* `:redrive_policy`
* `:fifo_queue`
* `:content_based_deduplication`

In addition to the SQS options, you can also pass the following:

* `:base_backoff_in_ms` - The base factor used to exponentially backoff when a request fails. Defaults to `10` when not specified. Can also be set globally.
* `:max_backoff_in_ms` - The maximum backoff when a request fails. Defaults to `10_000` when not specified. Can also be set globally.
* `:region` - The AWS region to use. Defaults to `"us-east-1"` when not specified. Can also be set globally.

## Configuring a Subscriber

Inside an `incoming` block for a broker, you can define subscriptions to queues. Conduit will route messages on those
queues to your subscribers.

``` elixir
defmodule MyApp.Broker do
  incoming MyApp do
    subscribe :my_subscriber, MySubscriber, from: "my-queue"
    subscribe :my_other_subscriber, MyOtherSubscriber,
      from: "my-other-queue",
      max_number_of_messages: 10,
      worker_pool_size: 1
  end
end
```

### Options

ConduitSQS requires that you specify a `from` option, which states which queue to consume from.

For subscribing to a queue, ConduitSQS supports the same options that are specified in the SQS docs. See the
[SQS docs for receiving a message](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_ReceiveMessage.html)
to understand what each of the options mean. These options include:

* `:attribute_names`
* `:message_attribute_names`
* `:max_number_of_messages`
* `:visibility_timeout`
* `:wait_time_seconds`

For `attribute_names` and `message_attributes`, ConduitSQS will attempt to pull all attributes unless overriden. ConduitSQS defaults `max_number_of_messages` to `10`, which is the largest that SQS supports.

In addition to the SQS options, you can also pass the following:

* `:worker_pool_size` - The number of workers that simultaneously consume from that queue. Defaults to 5.
* `:max_demand` - Max number of messages in flow. Defaults to 1000.
* `:min_demand` - Minumum threshold of messages to cause pulling of more. Defaults to 500.
* `:base_backoff_in_ms` - The base factor used to exponentially backoff when a request fails. Defaults to `10` when not specified. Can also be set globally.
* `:max_backoff_in_ms` - The maximum backoff when a request fails. Defaults to `10_000` when not specified. Can also be set globally.
* `:region` - The AWS region to use. Defaults to `"us-east-1"` when not specified. Can also be set globally.

## Configuring a Publisher

Inside an `outgoing` block for a broker, you can define publications to queues. Conduit will deliver messages using the
options specified. You can override these options, by passing different options to your broker's `publish/3`.

``` elixir
defmodule MyApp.Broker do
  outgoing do
    publish :something, to: "my-queue"
    publish :something_else,
      to: "my-other-queue",
      delay_seconds: 11
  end
end
```

### Options

For publishing to a queue, ConduitSQS supports the same options that are specified in the SQS docs. See the
[SQS docs for publishing a message](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html)
to understand what each of the options mean. These options include:

* `:delay_seconds`
* `:message_deduplication_id`
* `:message_group_id`

These options may also be specified by setting headers on the message being published. Headers on the message will
trump any options specified in an `outgoing` block. For example:

``` elixir
message =
  %Conduit.Message{}
  |> put_header("message_group_id", "22")
```

ConduitSQS does not allow you to set the `message_attributes` option. Those will be filled from properties
on the message and from the message headers.

In addition to the SQS options, you can also pass the following:

* `:to` - The destination queue for the message. If the message already has it's destination set, this option will be ignored.
* `:max_attempts` - How many times to retry publishing a message. Defaults to `10` when not specified. Can also be set globally.
* `:base_backoff_in_ms` - The base factor used to exponentially backoff when a request fails. Defaults to `10` when not specified. Can also be set globally.
* `:max_backoff_in_ms` - The maximum backoff when a request fails. Defaults to `10_000` when not specified. Can also be set globally.
* `:region` - The AWS region to use. Defaults to `"us-east-1"` when not specified. Can also be set globally.
