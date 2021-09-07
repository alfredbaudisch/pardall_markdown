defmodule LiveMarkdown.FileWatcher do
  use GenServer
  alias LiveMarkdown.Content.{Receiver, Repository, FileParser}
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    schedule_next_reload_all()
    {:ok, %{watcher_pid: watcher_pid, pending_events: 0, processing_events: 0}}
  end

  def handle_info({:file_event, _, {_path, event} = data}, %{pending_events: pending} = state) do
    Logger.info("Received file event: #{inspect(data)}")

    if Receiver.is_event_valid?(event) do
      pending = pending + 1
      Logger.info("Event is valid. Pending events: #{pending}.")

      {:noreply, put_in(state[:pending_events], pending)}
    else
      {:noreply, state}
    end
  end

  def handle_info({:file_event, _, :stop}, state) do
    {:noreply, state}
  end

  def handle_info(
        :check_pending_events,
        %{pending_events: pending, processing_events: processing} = state
      )
      when pending > 0 and processing == 0 do
    Logger.info("Pending file events: #{pending}. Will reload content...")
    schedule_next_reload_all()
    {:noreply, put_in(state[:processing_events], pending)}
  end

  def handle_info(:check_pending_events, state) do
    schedule_next_recheck()
    {:noreply, state}
  end

  def handle_info(:reload_all, %{pending_events: pending, processing_events: processing} = state) do
    Logger.warn("Started reloading content...")

    Repository.init()
    FileParser.load_all!()
    schedule_next_recheck()

    Logger.warn("Content reload finished.")

    {:noreply,
     state
     |> Map.put(:pending_events, max(pending - processing, 0))
     |> Map.put(:processing_events, 0)}
  end

  defp schedule_next_recheck,
    do: Process.send_after(self(), :check_pending_events, recheck_interval())

  defp schedule_next_reload_all,
    do: Process.send_after(self(), :reload_all, 10)

  defp recheck_interval,
    do:
      Application.get_env(:live_markdown, LiveMarkdown.Content)[
        :check_pending_file_events_interval
      ]
end
