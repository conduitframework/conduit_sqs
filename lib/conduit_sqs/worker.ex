defmodule ConduitSQS.Worker do
  @moduledoc """
  Worker requests messages and processes them
  """
  use GenStage
  import Injex
  inject :message_processor, ConduitSQS.MessageProcessor

  @behaviour GenStage

  defmodule State do
    @moduledoc false
    defstruct [:broker, :name, :adapter_opts]
  end

  def child_spec([broker, name, num, _] = args) do
    %{
      id: name(broker, name, num),
      start: {__MODULE__, :start_link, args},
      type: :worker
    }
  end

  @doc false
  def start_link(broker, sub_name, num, opts) do
    name = {:via, Registry, {ConduitSQS.registry_name(broker), name(broker, sub_name, num)}}

    GenStage.start_link(__MODULE__, [broker, sub_name, opts], name: name)
  end

  @doc false
  @impl true
  def init([broker, name, opts]) do
    poller_name = {:via, Registry, {ConduitSQS.registry_name(broker), ConduitSQS.Poller.name(broker, name)}}

    max_demand = Keyword.get(opts, :max_demand, 1000)
    min_demand = Keyword.get(opts, :min_demand, 500)

    {
      :consumer,
      %State{
        broker: broker,
        name: name,
        adapter_opts: opts
      },
      subscribe_to: [
        {poller_name, [max_demand: max_demand, min_demand: min_demand]}
      ]
    }
  end

  def name(broker, name, num) do
    {Module.concat(broker, Adapter.Worker), name, num}
  end

  @doc false
  @impl true
  def handle_events(messages, _from, %State{broker: broker, name: name, adapter_opts: opts} = state) do
    message_processor().process(broker, name, messages, opts)

    {:noreply, [], state, :hibernate}
  end

  # Hackney is leaking messages. This handles these messages, so the process doesn't crash.
  # https://github.com/benoitc/hackney/issues/464
  @impl true
  def handle_info({:ssl_closed, {:sslsocket, {:gen_tcp, _, _, _}, _}}, state) do
    {:noreply, [], state}
  end
end
