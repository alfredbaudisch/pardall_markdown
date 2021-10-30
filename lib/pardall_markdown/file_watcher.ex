defmodule PardallMarkdown.FileWatcher do
  use GenServer
  require Logger

  @recheck_interval Application.get_env(:pardall_markdown, PardallMarkdown.Content)[
                      :recheck_pending_file_events_interval
                    ]

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    dirs = Keyword.take(args, [:dirs])
    repository_url = Keyword.get(args, :remote_repository_url)

    if is_binary(repository_url) and repository_url != "" do
      Logger.info("Delayed FileWatcher start. FileWatcher will start after #{@recheck_interval}ms.")
      Process.send_after(self(), {:delayed_cold_start, dirs}, @recheck_interval)
      {:ok, %{watcher_pid: nil, pending_events: 0, processing_events: 0}}
    else
      {:ok, cold_start(dirs)}
    end
  end

  def handle_info({:delayed_cold_start, dirs}, _state) do
    {:noreply, cold_start(dirs)}
  end

  def handle_info({:file_event, _, {path, event} = data}, %{pending_events: pending} = state) do
    if should_process_event?(path, event) do
      pending = pending + 1
      Logger.info("Received valid file event: #{inspect(data)}. Pending events: #{pending}.")
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
        PardallMarkdown.reload_all()
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

  defp cold_start(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    Logger.info("FileWatcher started...")

    schedule_next_reload_all()
    %{watcher_pid: watcher_pid, pending_events: 1, processing_events: 1}
  end

  defp should_process_event?(path, _event), do: not PardallMarkdown.Content.Utils.is_path_hidden?(path)

  defp schedule_next_recheck,
    do: Process.send_after(self(), :check_pending_events, @recheck_interval)

  defp schedule_next_reload_all,
    do: Process.send_after(self(), :reload_all, 10)
end
