defmodule ConduitSQS.Poller do
  use GenStage

  defmodule State do
    defstruct [:queue, :subscriber_opts, :adapter_opts, demand: 0]
  end

  def start_link(queue, subscriber_opts, adapter_opts) do
    GenStage.start_link(__MODULE__, [queue, subscriber_opts, adapter_opts])
  end

  @impl true
  def init([queue, subscriber_opts, adapter_opts]) do
    {:producer, %State{
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
end
