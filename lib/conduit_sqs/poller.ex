defmodule ConduitSQS.Poller do
  @moduledoc """
  Handles demand from Workers by polling an SQS queue for messages
  """
  use GenStage
  import Injex
  require Logger
  inject :meta, ConduitSQS.Meta
  inject :sqs, ConduitSQS.SQS

  defmodule State do
    @type t :: %__MODULE__{
            broker: module,
            queue: String.t(),
            subscriber_opts: Keyword.t(),
            adapter_opts: Keyword.t(),
            demand: pos_integer
          }

    @moduledoc false
    defstruct [:broker, :queue, :subscriber_opts, :adapter_opts, demand: 0]
  end

  def child_spec([broker, subscription_name, _, _, _] = args) do
    %{
      id: name(broker, subscription_name),
      start: {__MODULE__, :start_link, args},
      type: :worker
    }
  end

  @doc false
  def start_link(broker, subscription_name, queue, subscriber_opts, adapter_opts) do
    name = {:via, Registry, {ConduitSQS.registry_name(broker), name(broker, subscription_name)}}

    GenStage.start_link(__MODULE__, [broker, queue, subscriber_opts, adapter_opts], name: name)
  end

  @doc false
  @impl true
  def init([broker, queue, subscriber_opts, adapter_opts]) do
    Process.send(self(), :check_active, [])

    {:producer,
     %State{
       broker: broker,
       queue: queue,
       subscriber_opts: subscriber_opts,
       adapter_opts: adapter_opts
     }, demand: :accumulate}
  end

  @doc false
  def name(broker, subscription) do
    {Module.concat(broker, Adapter.Poller), subscription}
  end

  @impl true
  @spec handle_demand(integer(), ConduitSQS.Poller.State.t()) :: {:noreply, [], ConduitSQS.Poller.State.t()}
  def handle_demand(new_demand, %State{demand: 0} = state) do
    Process.send(self(), :get_messages, [])

    {:noreply, [], %{state | demand: new_demand}}
  end

  def handle_demand(new_demand, %State{demand: current_demand} = state) do
    {:noreply, [], %{state | demand: new_demand + current_demand}}
  end

  @impl true
  @spec handle_info(:get_messages, ConduitSQS.Poller.State.t()) ::
          {:noreply, [Conduit.Message.t()], ConduitSQS.Poller.State.t(), :hibernate}
  @spec handle_info(:check_active, ConduitSQS.Poller.State.t()) :: {:noreply, [], ConduitSQS.Poller.State.t()}
  def handle_info(:get_messages, %State{queue: queue, demand: current_demand} = state) do
    fetch_limit = Keyword.get(state.subscriber_opts, :max_number_of_messages, 10)
    max_number_of_messages = min(min(fetch_limit, current_demand), 10)

    messages = sqs().get_messages(queue, max_number_of_messages, state.subscriber_opts, state.adapter_opts)
    handled_demand = length(messages)

    new_demand = current_demand - handled_demand

    cond do
      new_demand == 0 ->
        nil

      handled_demand == max_number_of_messages ->
        Process.send(self(), :get_messages, [])

      true ->
        Process.send_after(self(), :get_messages, 200)
    end

    {:noreply, messages, %{state | demand: new_demand}, :hibernate}
  end

  def handle_info(:check_active, %State{broker: broker, queue: queue} = state) do
    case meta().pollers_active?(broker) do
      true ->
        Logger.info("Starting poller for queue #{inspect(queue)} in #{inspect(get_region(state))}")
        GenStage.demand(self(), :forward)

      _ ->
        Process.send_after(self(), :check_active, 20)
    end

    {:noreply, [], state}
  end

  # Hackney is leaking messages. This handles these messages, so the process doesn't crash.
  # https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, {:sslsocket, {:gen_tcp, _, _, _}, _}}, state) do
    {:noreply, [], state}
  end

  defp get_region(state) do
    state.subscriber_opts[:region] || state.adapter_opts[:region] || "default region"
  end
end
