defmodule ConduitSQS.Poller do
  use GenStage

  defmodule State do
    defstruct [:queue, :subscriber_opts, :adapter_opts]
  end

  def start_link(queue, subscriber_opts, adapter_opts) do
    GenStage.start_link(__MODULE__, [queue, subscriber_opts, adapter_opts])
  end

  def init([queue, subscriber_opts, adapter_opts]) do
    {:producer, %State{
      queue: queue,
      subscriber_opts: subscriber_opts,
      adapter_opts: adapter_opts
    }, demand: :accumulate}
  end
end
