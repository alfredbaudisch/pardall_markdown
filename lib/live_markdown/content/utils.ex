defmodule LiveMarkdown.Content.Utils do
  def root_path, do: Application.get_env(:live_markdown, LiveMarkdown.Content)[:root_path]

  def static_assets_folder_name,
    do: Application.get_env(:live_markdown, LiveMarkdown.Content)[:static_assets_folder_name]

  def static_assets_path, do: Path.join(root_path(), static_assets_folder_name())

  def is_path_from_static_assets?(path), do: String.starts_with?(path, static_assets_path())

  def get_slug_from_path(path) do
    path
    |> String.replace(Path.extname(path), "")
    |> String.replace(root_path(), "")
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
