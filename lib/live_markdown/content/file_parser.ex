defmodule LiveMarkdown.Content.FileParser do
  require Logger
  alias LiveMarkdown.Content.Repository
  import LiveMarkdown.Content.Utils

  def load_all! do
    root_path()
    |> extract_folder!()
  end

  def extract!(path) do
    # Static assets are not parsed nor indexed
    if not is_path_from_static_assets?(path) do
      if File.exists?(path) do
        if File.dir?(path),
          do: extract_folder!(path),
          else: extract_file!(path)
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
  end

  defp extract_file!(path) do
    case path |> Path.extname() |> String.downcase() do
      extname when extname in [".md", ".markdown"] ->
        parse!(path)

      _ ->
        Logger.warn("Ignored file #{path}")
    end
  end

  defp parse!(path) do
    with {:ok, raw_content} <- File.read(path),
         {:ok, attrs, body} <- parse_contents(path, raw_content),
         {:ok, attrs} <- validate_attrs(attrs),
         {:ok, body_html, _} <- markdown_to_html(body),
         {:ok, summary_html, _} <- maybe_summary_to_html(attrs) do
      attrs =
        attrs
        |> extract_and_put_slug(path)
        |> extract_and_put_categories(path)
        |> parse_and_put_date!()
        |> Map.put(:summary, summary_html)

      Repository.push_post(path, attrs, body_html)
      Logger.info("Pushed converted Markdown: #{path}")
    else
      {:error, error} ->
        Logger.error("Could not parse file #{path}: #{inspect(error)}")

      {:error, _, error} ->
        Logger.error("Could not render Markdown file #{path}: #{inspect(error)}")
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

  defp maybe_summary_to_html(%{summary: summary}) when is_binary(summary) and summary != "",
    do: summary |> markdown_to_html()

  defp maybe_summary_to_html(_), do: {:ok, nil, :ignore}

  defp markdown_to_html(content), do: content |> Earmark.as_html(escape: false)

  defp extract_and_put_slug(attrs, path),
    do: Map.put(attrs, :slug, path |> remove_root_path() |> extract_slug_from_path())

  defp extract_and_put_categories(attrs, path),
    do: Map.put(attrs, :categories, path |> remove_root_path() |> extract_categories_from_path())

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
