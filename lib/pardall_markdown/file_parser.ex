defmodule PardallMarkdown.FileParser do
  require Logger
  alias PardallMarkdown.Repository
  import PardallMarkdown.Content.Utils
  import PardallMarkdown.Content.HtmlUtils

  def load_all! do
    root_path()
    |> extract_folder!()
  end

  def extract!(path) do
    if should_extract_path?(path) do
      if File.dir?(path),
        do: extract_folder!(path),
        else: extract_file!(path)
    end
  end

  # Static assets are not parsed nor indexed, neither files and folders that start with "."
  defp should_extract_path?(path),
    do:
      File.exists?(path) and not is_path_from_static_assets?(path) and
        not is_file_hidden?(path)

  defp is_file_hidden?(path), do: String.starts_with?(".", Path.basename(path))

  defp extract_folder_if_valid!(path),
    do: if(should_extract_path?(path), do: extract_folder!(path))

  defp extract_folder!(parent_path) do
    for child <- File.ls!(parent_path),
        path = Path.join(parent_path, child) do
      if File.dir?(path), do: extract_folder_if_valid!(path), else: extract_file_if_valid!(path)
    end
  end

  defp extract_file_if_valid!(path),
    do: if(should_extract_path?(path), do: extract_file!(path))

  defp extract_file!(path) do
    case path |> Path.extname() |> String.downcase() do
      extname when extname in [".md", ".markdown"] ->
        parse!(path)

      _ ->
        Logger.warn("Ignored file #{path}")
    end
  end

  defp parse!(path) do
    Logger.info("Parsing file #{path}...")
    is_index? = is_index_file?(path)

    with {:ok, raw_content} <- File.read(path),
         {:ok, attrs, body} <- parse_contents(path, raw_content),
         {:ok, body_html, _} <- markdown_to_html(body),
         {:ok, summary_html, _} <- maybe_summary_to_html(attrs),
         {:ok, date} <- parse_or_get_date(attrs, path) do
      attrs =
        attrs
        |> extract_and_put_slug(path)
        |> extract_and_put_categories(path)
        |> maybe_put_title(path, is_index?)
        |> Map.put(:summary, summary_html)
        |> Map.put(:date, date)
        |> Map.put(:is_index, is_index?)

      body_html = maybe_convert_links(body_html)

      {:ok, body_html, toc} = generate_anchors_and_toc(body_html, attrs)
      attrs = attrs |> Map.put(:toc, toc)

      Logger.info("Pushed converted Markdown: #{path}")
      Repository.push_post(path, attrs, body_html)
    else
      {:error, error} = res ->
        Logger.error("Could not parse file #{path}: #{inspect(error)}")
        res

      {:error, _, error} ->
        Logger.error("Could not render Markdown file #{path}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp parse_contents(path, contents) do
    split_first_line? =
      Application.get_env(:pardall_markdown, PardallMarkdown.Content, false)[
        :should_try_split_content_title_from_first_line
      ]

    if split_first_line? do
      case :binary.split(contents, ["\n\n", "\r\n\r\n"]) do
        [_] ->
          parse_metadata_from_contents(path, contents)

        [title, contents] ->
          case parse_metadata_from_contents(path, contents) do
            # A title from the metadata always has priority
            {:ok, %{title: custom_title}, _} = parsed
            when is_binary(custom_title) and custom_title != "" ->
              parsed

            # Use the title from the first line
            {:ok, attrs, body} ->
              {:ok, attrs |> Map.put(:title, title), body}

            other -> other
          end
      end
    else
      parse_metadata_from_contents(path, contents)
    end
  end

  # From https://github.com/dashbitco/nimble_publisher
  defp parse_metadata_from_contents(path, contents) do
    is_markdown_metadata_required? =
      Application.get_env(:pardall_markdown, PardallMarkdown.Content, true)[
        :is_markdown_metadata_required
      ]

    case :binary.split(contents, ["\n---\n", "\r\n---\r\n"]) do
      [_] when not is_markdown_metadata_required? ->
        {:ok, %{}, contents}

      [_] ->
        {:error, "could not find separator --- in #{inspect(path)}"}

      [code, body] ->
        try do
          case Code.eval_string(code, []) do
            {%{} = attrs, _} ->
              {:ok, attrs |> atomize_keys(), body}

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

  defp maybe_summary_to_html(%{summary: summary}) when is_binary(summary) and summary != "",
    do: summary |> markdown_to_html()

  defp maybe_summary_to_html(_), do: {:ok, nil, :ignore}

  defp markdown_to_html(content), do: content |> Earmark.as_html(escape: false)

  defp extract_and_put_slug(attrs, path),
    do: Map.put(attrs, :slug, path |> remove_root_path() |> extract_slug_from_path())

  defp extract_and_put_categories(attrs, path),
    do: Map.put(attrs, :categories, path |> remove_root_path() |> extract_categories_from_path())

  defp maybe_put_title(attrs, path, is_index?)

  # Custom title provided
  defp maybe_put_title(%{title: title} = attrs, _path, _) when is_binary(title) and title != "",
    do: attrs

  # Page is the index page and a custom title wasn't provided,
  # set the main taxonomy name as the page title
  defp maybe_put_title(%{categories: categories} = attrs, _path, true),
    do: Map.put(attrs, :title, List.last(categories)[:title])

  # A post and custom title not provided,
  # title-fy the file name
  defp maybe_put_title(attrs, path, false),
    do: Map.put(attrs, :title, extract_title_from_path(path))

  # Date provided in the markdown file, try to parse it
  defp parse_or_get_date(%{date: date}, _path) when is_binary(date) and date != "" do
    cond do
      is_date?(date) ->
        {:ok, date} = date |> Date.from_iso8601()
        DateTime.new(date, ~T[00:00:00], "Etc/UTC")

      is_datetime?(date) ->
        {:ok, datetime, _} = date |> DateTime.from_iso8601()
        {:ok, datetime}

      true ->
        {:error, "Post :date must be in a valid ISO datetime, received: #{date}"}
    end
  end

  defp parse_or_get_date(_, path) do
    {:ok, %File.Stat{ctime: {{a, b, c}, {d, e, f}}}} = File.lstat(path)

    NaiveDateTime.new!(a, b, c, d, e, f)
    |> DateTime.from_naive("Etc/UTC")
  end

  defp maybe_convert_links(html) do
    should_convert? =
      Application.get_env(:pardall_markdown, PardallMarkdown.Content)[
        :convert_internal_links_to_live_links
      ]

    if should_convert? do
      {:ok, html} = convert_internal_links_to_live_links(html)
      html
    else
      html
    end
  end
end
