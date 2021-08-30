defmodule LiveMarkdown.Content.ParseFile do
  require Logger
  alias LiveMarkdown.Content.{Utils, Repository}

  def parse(path) do
    case Path.extname(path) do
      ".md" ->
        parse_markdown(path)

      _ ->
        Logger.info(
          "Content.ParseFile] Received file #{path}, but a parser for this file type has not been implemented yet"
        )
    end
  end

  defp parse_markdown(path) do
    with {:ok, raw_content} <- File.read(path),
         {:ok, html_content, _} <- Earmark.as_html(raw_content) do
      Repository.push(path, html_content, get_title_from_path(path))
      Logger.info("[Content.ParseFile] Pushed rendered Markdown: #{path}")
    else
      {:error, error} ->
        Logger.error("[Content.ParseFile] Could not read file #{path}", error)

      {:error, _, error} ->
        Logger.error("[Content.ParseFile] Could not render Markdown file #{path}", error)
    end
  end

  defp get_title_from_path(path) do
    path
    |> Path.basename()
    |> String.replace(Path.extname(path), "")
  end
end
