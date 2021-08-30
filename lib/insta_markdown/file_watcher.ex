defmodule InstaMarkdown.FileWatcher do
  use GenServer
  alias InstaMarkdown.FileProcessor

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info(
        {:file_event, watcher_pid, {path, events} = data},
        %{watcher_pid: watcher_pid} = state
      ) do
    IO.inspect(data)
    # Your own logic for path and events
    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    # Your own logic when monitor stop
    {:noreply, state}
  end
end
