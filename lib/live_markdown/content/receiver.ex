defmodule LiveMarkdown.Content.Receiver do
  alias LiveMarkdown.Content.FileParser

  @moduledoc """
  Process `FileSystem` events, directing the paths to their
  corresponding pipelines (files and folders) depending on the received events.
  
  ## Folder Events
  Folder events are followed by the `:isdir` flag.
  
  ### `:moved_from`
  
    - Folder renamed or moved: source path.
    - Folder deleted: no related `:moved_to` event will be created,
    only a single `:moved_from` event.
  
  ### `:moved_to`
  
    - Folder renamed or moved: destination path, there's a related `:moved_from` event.
    - Folder moved from an external folder into the watched folder:
    there's no related `:moved_from` event, only a single `:moved_to` event.
      - Even if the folder is not empty, only a single `:moved_to` is created
      for the folder, without any event being created for the folder's contents
      (not even for subfolders).
  
  ## File Events
  ### `:moved_from`
  
    - File renamed or moved: source path.
    - File deleted: no related `:moved_to` event will be created,
    only a single `:moved_from` event.
  
  ### `:moved_to`
  
    - File renamed or moved: destination path, there's a related `:moved_from` event.
    - File moved from an external folder into the watched folder:
    there's no related `:moved_from` event, only a single `:moved_to` event.
  
  ### `:created` and `:modified`
  
    - When a file is created, the event `:created` is created.
    - For each modification, there's an event `:modified`.
    - Finishing the creation and/or modification of a file ends with `[:modified, :closed]`.
    - The event `:attribute` is also created during file creation/modification,
    but it's currently of no use for the purpose of this application.
  """

  # `:moved_from`:
  #   - Folder renamed or moved: source path.
  #   - Folder deleted
  # `:moved_to`:
  #   - Folder renamed or moved: destination path
  #   - Folder moved from an external folder
  def event(path, [event, :isdir]) when event in [:moved_from, :moved_to],
    do: FileParser.extract!(path)

  # `:moved_from`:
  #   - File renamed or moved: source path.
  #   - File deleted
  # `:moved_to`:
  #   - File renamed or moved: destination path
  #   - File moved from an external folder
  # `:modified, :closed`:
  #   - Final event related to a file's creation or modification,
  #     it's the only one needed to be tracked in order to react
  #     to a new or updated file.
  def event(path, event)
      when event in [
             [:moved_from],
             [:moved_to],
             [:modified, :closed]
           ],
      do: FileParser.extract!(path)

  def event(_path, _events), do: {:ok, :ignore}

  def is_event_valid?([event, :isdir]) when event in [:moved_from, :moved_to], do: true

  def is_event_valid?(event)
      when event in [
             [:moved_from],
             [:moved_to],
             [:modified, :closed]
           ],
      do: true

  @doc """
  Returns whether a file event should be processed or not. Check
  the description of `LiveMarkdown.Content.Receiver` for more details.
  """
  def is_event_valid?(_), do: false
end
