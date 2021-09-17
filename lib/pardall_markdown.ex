defmodule PardallMarkdown do
  def reload_all do
    PardallMarkdown.Repository.init()
    PardallMarkdown.FileParser.load_all!()
    PardallMarkdown.Repository.rebuild_indexes()
    :ok
  end
end
