defmodule LiveMarkdown.FileWatcher do
  use GenServer
  alias LiveMarkdown.Content.Receiver
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    {:ok, watcher_pid} = FileSystem.start_link(args)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info(
        {:file_event, _, {path, events} = data},
        %{watcher_pid: _} = state
      ) do
    Logger.info("[FileWatcher] #{inspect(data)}")
    Receiver.event(path, events)
    {:noreply, state}
  end

  def handle_info({:file_event, _, :stop}, %{watcher_pid: _} = state) do
    {:noreply, state}
  end
end
