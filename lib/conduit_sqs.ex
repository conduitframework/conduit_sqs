defmodule ConduitSQS do
  @moduledoc """
  Implements the Conduit adapter interface for SQS
  """
  use Conduit.Adapter
  use Supervisor
  require Logger
  alias ConduitSQS.{Meta, SQS, OptionValidator}

  @doc """
  Implents Conduit.Adapter.start_link/4 callback
  """
  @impl true
  def start_link(broker, topology, subscribers, opts) do
    OptionValidator.validate!(topology, subscribers, opts)
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts], name: __MODULE__)
  end

  @doc false
  @impl true
  def init([broker, topology, subscribers, opts]) do
    Logger.info("SQS Adapter started!")
    import Supervisor.Spec

    Meta.create(broker)

    children = [
      supervisor(Registry, [[keys: :unique, name: registry_name(broker)]]),
      worker(ConduitSQS.Setup, [broker, topology, opts], restart: :transient),
      supervisor(ConduitSQS.PollerSupervisor, [broker, subscribers, opts]),
      supervisor(ConduitSQS.WorkerGroupSupervisor, [broker, subscribers, opts])
    ]

    supervise(children, strategy: :one_for_one)
  end

  @doc """
  Implents Conduit.Adapter.publish/4 callback
  """
  @impl true
  def publish(_broker, message, config, opts) do
    SQS.publish(message, config, opts)
  end

  @doc false
  def registry_name(broker) do
    Module.concat([broker, Registry])
  end
end
