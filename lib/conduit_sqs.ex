defmodule ConduitSQS do
  @moduledoc """
  Implements the Conduit adapter interface for SQS
  """
  use Conduit.Adapter
  use Supervisor
  require Logger
  alias ConduitSQS.{Meta, SQS, OptionValidator}

  def child_spec([broker, _, _, _] = args) do
    %{
      id: name(broker),
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  @doc """
  Implents Conduit.Adapter.start_link/4 callback
  """
  @impl true
  def start_link(broker, topology, subscribers, opts) do
    OptionValidator.validate!(topology, subscribers, opts)
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts], name: name(broker))
  end

  @doc false
  @impl true
  def init([broker, topology, subscribers, opts]) do
    Logger.info("SQS Adapter started!")

    Meta.create(broker)

    children = [
      {Registry, keys: :unique, name: registry_name(broker)},
      {ConduitSQS.Setup, [broker, topology, opts]},
      {ConduitSQS.PollerSupervisor, [broker, subscribers, opts]},
      {ConduitSQS.WorkerGroupSupervisor, [broker, subscribers, opts]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc false
  def name(broker) do
    Module.concat(broker, Adapter)
  end

  @doc """
  Implents Conduit.Adapter.publish/3 callback
  """
  @impl true
  def publish(message, config, opts) do
    SQS.publish(message, config, opts)
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
    Module.concat([broker, Adapter.Registry])
  end
end
