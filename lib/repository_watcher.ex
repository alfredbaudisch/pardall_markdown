defmodule PardallMarkdown.RepositoryWatcher do
  @moduledoc """

  """
  use GenServer
  require Logger

  alias PardallMarkdown.RepositoryProviders.{Git}
  alias PardallMarkdown.RepositoryProvider, as: Repository

  @recheck_interval Application.get_env(:pardall_markdown, PardallMarkdown.Content)[
    :recheck_pending_remote_events_interval
  ]

  def start_link(args) do
    GenServer.start_link(__MODULE__, provider: args[:repo])
  end

  @impl true
  def init(provider) do
    Process.send_after(self(), {:cold_start, :provider, provider}, @recheck_interval)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:check_pending_remote_events, %{repo: repo} = state) do
    # Fetch any potential changes from remote.
    Git.fetch(repo)
    send_next_recheck()
    {:noreply, state}
  end

  # In eithe case of :no_updates or :updates we don't care about what happened.
  # keep passing state. FileWatcher and FileParser will handle any changes at
  # the local_path.

  @impl true
  def handle_info({_, :no_updates}, state), do: {:noreply, state}

  @impl true
  def handle_info({_, {:updates, _}}, state), do: {:noreply, state}

  @impl true
  def handle_info({:cold_start, :provider, provider}, _state) do
    repo = Git.repository()
    state = %Repository{repo: repo, provider: provider}
    send_next_recheck()
    {:noreply, state}
  end

  defp send_next_recheck, do: Process.send_after(self(), :check_pending_remote_events, @recheck_interval)
end
