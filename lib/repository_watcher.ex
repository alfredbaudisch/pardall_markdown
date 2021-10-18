defmodule PardallMarkdown.RepositoryWatcher do
  @moduledoc """

  """
  use GenServer
  require Logger

  alias PardallMarkdown.RepositoryProviders.{Git}

  @recheck_interval Application.get_env(:pardall_markdown, PardallMarkdown.Content)[
    :recheck_pending_remote_events_interval
  ]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, args)
  end

  @impl true
  def init(args) do
    # Clone and create a local path for the provided remote repository.
    Git.repository()
    # Begin tick.
    send_next_recheck()
    # Send on initial state that handle_info/2 will receive.
    # QUESTION: What should this be?
    {:ok, args}
  end

  @impl true
  def handle_info(msg, state) do
    IO.puts("handle_info/2")
    IO.inspect(msg)
    IO.inspect(state)
    {:noreply, state}
  end

  defp send_next_recheck, do: Process.send_after(self(), :check_pending_remote_events, @recheck_interval)
end
