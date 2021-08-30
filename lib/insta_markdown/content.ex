defmodule InstaMarkdown.Content do
  alias InstaMarkdown.Content.ReceiveWatcherEvent

  def receive_watcher_event({path, events}) do
    ReceiveWatcherEvent.process_event(path, events)
  end
end
