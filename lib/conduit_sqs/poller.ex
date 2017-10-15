defmodule ConduitSQS.Poller do
  use GenStage
  import Injex
  inject :meta, ConduitSQS.Meta
  inject :sqs, ConduitSQS.SQS

  defmodule State do
    defstruct [:broker, :queue, :subscriber_opts, :adapter_opts, demand: 0]
  end

  def start_link(broker, subscription_name, queue, subscriber_opts, adapter_opts) do
    name = {:via, Registry, {ConduitSQS.registry_name(broker), {__MODULE__, subscription_name}}}

    GenStage.start_link(__MODULE__, [broker, queue, subscriber_opts, adapter_opts], name: name)
  end

  @impl true
  def init([broker, queue, subscriber_opts, adapter_opts]) do
    Process.send(self(), :check_active, [])

    {:producer, %State{
      broker: broker,
      queue: queue,
      subscriber_opts: subscriber_opts,
      adapter_opts: adapter_opts
    }, demand: :accumulate}
  end

  @impl true
  def handle_demand(new_demand, %State{demand: 0} = state) do
    Process.send(self(), :get_messages, [])

    {:noreply, [], %{state | demand: new_demand}}
  end
  def handle_demand(new_demand, %State{demand: current_demand} = state) do
    {:noreply, [], %{state | demand: new_demand + current_demand}}
  end

  @impl true
  def handle_info(:get_messages, %State{queue: queue, demand: current_demand} = state) do
    fetch_limit = Keyword.get(state.subscriber_opts, :max_number_of_messages, 10)
    max_number_of_messages = min(min(fetch_limit, current_demand), 10)

    messages = sqs().get_messages(queue, max_number_of_messages, state.subscriber_opts, state.adapter_opts)
    handled_demand = length(messages)

    new_demand = current_demand - handled_demand

    cond do
      new_demand == 0 -> nil
      handled_demand == max_number_of_messages ->
        Process.send(self(), :get_messages, [])
      true ->
        Process.send_after(self(), :get_messages, 200)
    end

    {:noreply, messages, %{state | demand: new_demand}}
  end

  @impl true
  def handle_info(:check_active, %State{broker: broker} = state) do
    case meta().pollers_active?(broker) do
      true -> GenStage.demand(self(), :forward)
      _ -> Process.send_after(self(), :check_active, 20)
    end

    {:noreply, [], state}
  end
end
