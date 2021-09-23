defmodule PardallMarkdown.MetadataParser do
  @type option :: {:is_index?, boolean(), :is_required?, boolean()}
  @type options :: [option]

  @callback parse(String.t(), String.t(), options) ::
              {:ok, map(), String.t()} | {:error, String.t()}
end
