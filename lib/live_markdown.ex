defmodule LiveMarkdown do
  @moduledoc """
  LiveMarkdown keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def reload_all do
    LiveMarkdown.Content.Repository.init()
    LiveMarkdown.Content.FileParser.load_all!()
  end
end
