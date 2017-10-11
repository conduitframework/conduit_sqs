defmodule ConduitSQS.SQS do
  require Logger
  alias ExAws.SQS, as: Client
  alias Conduit.Message
  alias ConduitSQS.SQS.Options

  def setup_topology(topology, opts) do
    Enum.map(topology, &setup(&1, opts))
  end

  defp setup({:queue, name, queue_opts}, opts) do
    Logger.info("Declaring queue #{name}")

    name
    |> Client.create_queue(queue_opts)
    |> ExAws.request!(opts)
    |> get_in([:body])
  end
  defp setup(_, _), do: nil

  def publish(%Message{body: body} = message, config, opts) do
    message.destination
    |> Client.send_message(body, Options.from(message, opts))
    |> ExAws.request!(config)
    |> get_in([:body])
  end

  def get_messages(queue, max_number_of_messages, subscriber_opts, adapter_opts) do
    sub_opts = build_subsriber_opts(max_number_of_messages, subscriber_opts)

    queue
    |> Client.receive_message(sub_opts)
    |> ExAws.request!(adapter_opts)
    |> get_in([:body])
    |> __MODULE__.Message.to_conduit_messages(queue)
  end

  defp build_subsriber_opts(max_number_of_messages, subscriber_opts) do
    subscriber_opts
    |> Keyword.put(:max_number_of_messages, max_number_of_messages)
    |> Keyword.put_new(:attribute_names, :all)
    |> Keyword.put_new(:message_attribute_names, :all)
  end
end
