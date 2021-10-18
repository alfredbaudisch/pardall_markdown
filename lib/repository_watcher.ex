defmodule PardallMarkdown.RepositoryWatcher do
  @moduledoc """

  """
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, args)
  end

  @impl true
  def init(args) do
    IO.inspect(args)
    {:ok, args}
  end
end
