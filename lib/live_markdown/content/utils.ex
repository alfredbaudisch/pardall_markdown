defmodule LiveMarkdown.Content.Utils do
  def root_folder, do: Application.get_env(:live_markdown, LiveMarkdown.Content)[:root_folder]

  def get_slug_from_path(path) do
    path
    |> String.replace(Path.extname(path), "")
    |> String.replace(root_folder(), "")
    |> Slug.slugify(ignore: "/")
  end

  def get_title_from_path(path) do
    path
    |> Path.basename()
    |> String.replace(Path.extname(path), "")
    |> String.replace("-", " ")
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
