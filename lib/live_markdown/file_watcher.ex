defmodule LiveMarkdown.FileWatcher do
  use GenServer
  alias LiveMarkdown.Content.Receiver

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info(
        {:file_event, _watcher_pid, {path, events}},
        %{watcher_pid: _watcher_pid} = state
      ) do
    Receiver.event(path, events)
    {:noreply, state}
  end

  def handle_info({:file_event, _watcher_pid, :stop}, %{watcher_pid: _watcher_pid} = state) do
    # Your own logic when monitor stop
    {:noreply, state}
  end
end
