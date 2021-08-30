defmodule LiveMarkdown.Content.Cache do
  require Logger
  @cache_name Application.compile_env(:live_markdown, [LiveMarkdown.Content, :cache_name])

  def save(key, value) do
    Logger.info("[Content.Cache] saved #{key}, #{inspect(value)}")
    ConCache.put(@cache_name, key, value)
  end

  def get_all do
    ConCache.ets(@cache_name)
    |> :ets.tab2list()
    |> Enum.map(fn {_key, value} -> value end)
  end
end
