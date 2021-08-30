defmodule InstaMarkdown.Content.ParseFile do
  require Logger
  alias InstaMarkdown.Content.{Utils, Repository}

  def parse(path) do
    case Path.extname(path) do
      ".md" ->
        parse_markdown(path)

      _ ->
        Logger.info(
          "Received file #{path}, but a parser for this file type has not been implemented yet"
        )
    end
  end

  defp parse_markdown(path) do
    with {:ok, raw_content} <- File.read(path),
         {:ok, html_content, _} <- Earmark.as_html(raw_content) do
      Repository.push(path, html_content, title: get_title_from_path(path))
      Logger.info("Parsed and pushed Markdown file #{path}")
    else
      {:error, error} -> Logger.error("Could not read file #{path}", error)
      {:error, _, error} -> Logger.error("Could not render Markdown file #{path}", error)
    end
  end

  defp get_title_from_path(path) do
    path
    |> Path.basename()
    |> String.replace(Path.extname(path), "")
  end
end
