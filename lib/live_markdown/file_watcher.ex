defmodule LiveMarkdown.FileWatcher do
  use GenServer
  alias LiveMarkdown.Content.Receiver
  require Logger

  @recheck_interval Application.compile_env!(:live_markdown, [
                      LiveMarkdown.Content,
                      :recheck_pending_file_events_interval
                    ])

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    schedule_next_reload_all()
    {:ok, %{watcher_pid: watcher_pid, pending_events: 1, processing_events: 1}}
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

  # The ideal scenario is to NEVER reach this stage:
  # the whole content should be built before the next
  # `@recheck_interval` happens.
  def handle_info(
        :check_pending_events,
        %{pending_events: pending, processing_events: processing} = state
      )
      when pending > 0 and processing > 0 do
    Logger.warn(
      "Content reloader is already busy processing #{processing} event(s) (for a total of #{pending} pending event(s)). Will re-schedule. If this happens frequently, consider increasing the interval :recheck_pending_file_events_interval."
    )

    schedule_next_recheck()
    {:noreply, state}
  end

  def handle_info(:check_pending_events, state) do
    schedule_next_recheck()
    {:noreply, state}
  end

  def handle_info(:reload_all, %{processing_events: processing} = state) do
    Logger.info("Started reloading content...")

    gen_pid = self()

    Task.start(fn ->
      notify = fn amount -> send(gen_pid, {:notify_finished_processing, amount}) end

      try do
        LiveMarkdown.reload_all()
        Logger.info("Content reload finished.")
        notify.(processing)
      rescue
        e ->
          notify.(0)
          Logger.error("Could not reload content.")
          reraise e, __STACKTRACE__
      end
    end)

    schedule_next_recheck()
    {:noreply, state}
  end

  def handle_info({:notify_finished_processing, amount}, %{pending_events: pending} = state) do
    {:noreply,
     state
     |> Map.put(:pending_events, max(pending - amount, 0))
     |> Map.put(:processing_events, 0)}
  end

  defp schedule_next_recheck,
    do: Process.send_after(self(), :check_pending_events, @recheck_interval)

  defp schedule_next_reload_all,
    do: Process.send_after(self(), :reload_all, 10)
end
