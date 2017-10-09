defmodule ConduitSQS.SQS do
  def setup_topology(topology, opts) do
    Enum.each(topology, &setup(&1, opts))
  end

  defp setup({:queue, name, queue_opts}, opts) do

  end
  defp setup(_, _), do: nil
end
