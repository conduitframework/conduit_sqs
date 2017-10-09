defmodule ConduitSQS.SQS do
  require Logger
  alias ExAws.SQS, as: Client

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
end
