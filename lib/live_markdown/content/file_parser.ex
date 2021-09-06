defmodule LiveMarkdown.Content.FileParser do
  require Logger
  alias LiveMarkdown.Content.{Repository, Cache}
  import LiveMarkdown.Content.Utils

  def load_all! do
    root_path()
    |> extract_folder!()
  end

  def extract!(path) do
    # I don't like nested if's in Elixir, but there's no better
    # way to do this in this specific case
    if not is_path_from_static_assets?(path) do
      if File.exists?(path) do
        if File.dir?(path),
          do: extract_folder!(path),
          else: extract_file!(path)
      else
        Repository.delete_path(path)
      end
    end
  end

  defp extract_folder_if_valid!(path),
    do: if(not is_path_from_static_assets?(path), do: extract_folder!(path))

  defp extract_folder!(parent_path) do
    for child <- File.ls!(parent_path),
        path = Path.join(parent_path, child) do
      if File.dir?(path), do: extract_folder_if_valid!(path), else: extract_file!(path)
    end

    # Index contents only for the current folder, that's why
    # we need another comprehension here. Each iteraction
    # of `extract_folder/2` indexes itself into cache.
    path_index_contents =
      for child <- File.ls!(parent_path),
          path = Path.join(parent_path, child) do
        %{path: path, slug: path |> remove_root_path() |> extract_slug_from_path()}
      end

    Cache.save_path(parent_path, path_index_contents)
  end

  defp extract_file!(path) do
    case path |> Path.extname() |> String.downcase() do
      extname when extname in [".md", ".markdown"] ->
        parse!(path)

      _ ->
        Logger.warn("[Content.ParseFile] Received file #{path}, but no need to parse")
    end
  end

  defp parse!(path) do
    with {:ok, raw_content} <- File.read(path),
         {:ok, attrs, body} <- parse_contents(path, raw_content),
         {:ok, attrs} <- validate_attrs(attrs),
         {:ok, html_content, _} <- convert_markdown_body(body) do
      attrs =
        attrs
        |> put_slug(path)
        |> parse_and_put_date!()

      Repository.push(path, attrs, html_content)
      Logger.info("[Content.ParseFile] Pushed converted Markdown: #{path}")
    else
      {:error, error} ->
        Logger.error("[Content.ParseFile] Could not parse file #{path}: #{inspect(error)}")

      {:error, _, error} ->
        Logger.error(
          "[Content.ParseFile] Could not render Markdown file #{path}: #{inspect(error)}"
        )
    end
  end

  # From https://github.com/dashbitco/nimble_publisher
  defp parse_contents(path, contents) do
    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] ->
        {:error, "could not find separator --- in #{inspect(path)}"}

      [code, body] ->
        case Code.eval_string(code, []) do
          {%{} = attrs, _} ->
            {:ok, attrs, body}

          {other, _} ->
            {:error,
             "expected attributes for #{inspect(path)} to return a map, got: #{inspect(other)}"}
        end
    end
  end

  defp validate_attrs(%{title: title, date: date} = attrs)
       when is_binary(title) and not is_nil(date) and title != "",
       do: {:ok, attrs}

  defp validate_attrs(_), do: {:error, "attrs must contain :title and :date"}

  defp convert_markdown_body(body), do: body |> Earmark.as_html()

  defp put_slug(attrs, path),
    do: Map.put(attrs, :slug, path |> remove_root_path() |> extract_slug_from_path())

  defp parse_and_put_date!(%{date: date} = attrs) do
    date =
      case date do
        %Date{} = dt -> DateTime.new!(dt, ~T[00:00:00])
        %NaiveDateTime{} = dt -> DateTime.from_naive!(dt, "Etc/UTC")
        %DateTime{} = dt -> dt
        _ -> raise "Post :date must be in a valid Elixir date format, received: #{date}"
      end

    Map.put(attrs, :date, date)
  end
end
