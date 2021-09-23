defmodule PardallMarkdown.MetadataParser.ElixirMap do
  @behaviour PardallMarkdown.MetadataParser

  alias PardallMarkdown.Content.Utils

  @impl PardallMarkdown.MetadataParser
  def parse(path, contents, opts) do
    is_required? = Keyword.get(opts, :is_required?, true)

    # Contains parts rom https://github.com/dashbitco/nimble_publisher
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] when not is_required? ->
        {:ok, %{}, contents}

      [_] ->
        {:error, "could not find separator --- in #{inspect(path)}"}

      [code, body] ->
        try do
          case Code.eval_string(code, []) do
            {%{} = attrs, _} ->
              {:ok, attrs |> Utils.atomize_keys(), body}

            {other, _} ->
              {:error,
               "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"}
          end
        rescue
          e in SyntaxError ->
            {:error, e}
        end
    end
  end
end
