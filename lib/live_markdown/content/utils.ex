defmodule LiveMarkdown.Content.Utils do
  def root_folder, do: Application.get_env(:live_markdown, LiveMarkdown.Content)[:root_folder]

  def get_slug_from_path(path, type) do
    cond do
      type in [:text, :html] ->
        path
        |> String.replace(Path.extname(path), "")

      true ->
        path
    end
    |> String.replace(Utils.root_folder(), "")
    |> Slug.slugify(ignore: "/")
  end
end
