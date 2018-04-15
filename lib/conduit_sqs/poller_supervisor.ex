defmodule ConduitSQS.PollerSupervisor do
  @moduledoc """
  Manages pollers
  """
  use Supervisor

  def child_spec([broker, _, _] = args) do
    %{
      id: name(broker),
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  @doc false
  def start_link(broker, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, subscribers, opts], name: name(broker))
  end

  @doc false
  @impl true
  def init([broker, subscribers, opts]) do
    children =
      subscribers
      |> Enum.map(fn {name, subscriber_opts} ->
        {ConduitSQS.Poller, [broker, name, opts[:from], subscriber_opts, opts]}
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  def name(broker) do
    Module.concat(broker, Adapter.PollerSupervisor)
  end
end
