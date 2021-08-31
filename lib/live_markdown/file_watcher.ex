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
    Process.send_after(self(), :cold_start, 10)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  def handle_info(:cold_start, state) do
    Repository.init()
    FileParser.load_all!()
    {:noreply, state}
  end

  def handle_info({:file_event, _, {path, events} = data}, state) do
    Logger.info("[FileWatcher] #{inspect(data)}")
    Receiver.event(path, events)
    {:noreply, state}
  end

  def handle_info({:file_event, _, :stop}, state) do
    {:noreply, state}
  end
end
