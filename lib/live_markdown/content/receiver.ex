defmodule LiveMarkdown.Content.Receiver do
  alias LiveMarkdown.Content.ParseFile

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
  
  ### `:created`
  
    - Folder created.
  
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
    - The event `:attribute` is also created in file creation,
    but it's currently of no use for the purpose of this application.
  """

  # Folder renamed or moved: source path.
  # Folder deleted
  def event(path, [:moved_from, :isdir]) do
  end

  # Folder renamed or moved: destination path, there's a related `:moved_from` event.
  # Folder moved from an external folder
  def event(path, [:moved_to, :isdir]) do
  end

  def event(path, [:created, :isdir]) do
  end

  # File renamed or moved: source path.
  # File deleted
  def event(path, [:moved_from]) do
  end

  # File renamed or moved: destination path
  # File moved from an external folder
  def event(path, [:moved_to]) do
  end

  # Final event related to a file's creation or modification,
  # it's the only one needed to be tracked in order to react
  # to a new or updated filed.
  def event(path, [:modified, :closed]) do
    ParseFile.parse(path)
  end

  def event(_path, _events), do: {:ok, :ignore}
end
