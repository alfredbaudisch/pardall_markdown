defmodule InstaMarkdown.Content.Cache do
  @cache_name Application.compile_env(:insta_markdown, [InstaMarkdown.Content, :cache_name])

  def save(key, value) do
    ConCache.put(@cache_name, key, value)
  end
end
