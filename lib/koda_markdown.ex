defmodule KodaMarkdown do
  alias KodaMarkdown.Content

  def reload_all do
    Content.Repository.init()
    Content.FileParser.load_all!()
    Content.Repository.rebuild_indexes()
    :ok
  end
end
