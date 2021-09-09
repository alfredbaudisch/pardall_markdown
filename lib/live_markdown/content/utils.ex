defmodule LiveMarkdown.Content.Utils do
  @taxonomy_index_file "_index.md"
  @root_path Application.compile_env!(:live_markdown, [LiveMarkdown.Content, :root_path])
  @static_assets_folder_name Application.compile_env!(:live_markdown, [
                               LiveMarkdown.Content,
                               :static_assets_folder_name
                             ])

  def root_path, do: @root_path
  def static_assets_folder_name, do: @static_assets_folder_name
  def static_assets_path, do: Path.join(root_path(), static_assets_folder_name())

  def is_path_from_static_assets?(path), do: String.starts_with?(path, static_assets_path())

  def remove_root_path(path), do: path |> String.replace(root_path(), "")

  def taxonomy_index_file, do: @taxonomy_index_file
  def is_index_file?(path), do: Path.basename(path) == taxonomy_index_file()

  def is_sort_by_valid?(sort_by) when sort_by in [:title, :date, :slug, :position], do: true
  def is_sort_by_valid?(_), do: false
  def is_sort_order_valid?(sort_order) when sort_order in [:asc, :desc], do: true
  def is_sort_order_valid?(_), do: false

  def default_sort_by, do: :date
  def default_sort_order, do: :desc
  def default_taxonomy_sort_by, do: :title
  def default_taxonomy_sort_order, do: :asc
  def default_position, do: 100_000

  @doc """
  ## Examples

      iex> LiveMarkdown.Content.Utils.extract_slug_from_path("/blog/art/3d/post.md")
      "/blog/art/3d/post"

      iex> LiveMarkdown.Content.Utils.extract_slug_from_path("/blog/My new Project.md")
      "/blog/my-new-project"

      iex> LiveMarkdown.Content.Utils.extract_slug_from_path("/blog/_index.md")
      "/blog/-index"
  """
  def extract_slug_from_path(path) do
    path
    |> String.replace(Path.extname(path), "")
    |> Slug.slugify(ignore: "/")
  end

  @doc """
  Transforms a file name from a path into a readable post title.

  ## Examples

      iex> LiveMarkdown.Content.Utils.extract_title_from_path("/blog/art/3d/post-about-art.md")
      "Post about art"

      iex> LiveMarkdown.Content.Utils.extract_title_from_path("/blog/My new Project.md")
      "My new Project"
  """
  def extract_title_from_path(path) do
    path
    |> Path.basename()
    |> String.replace(Path.extname(path), "")
    |> capitalize_as_title()
  end

  @doc """
  Transforms a source string into a post title.

  ## Examples

      iex> LiveMarkdown.Content.Utils.capitalize_as_title("post-about-art")
      "Post about art"

      iex> LiveMarkdown.Content.Utils.capitalize_as_title("My new Project")
      "My new Project"

      iex> LiveMarkdown.Content.Utils.capitalize_as_title("2d 3D 4d-art: this is bugged, 3d should've been preserved as 3d not separate strings")
      "2d 3D 4d art: this is bugged, 3d should've been preserved as 3d not separate strings"

      iex> LiveMarkdown.Content.Utils.capitalize_as_title("Some Startup plans to expand quantum Platform of the Platforms with $500M investment")
      "Some Startup plans to expand quantum Platform of the Platforms with $500M investment"
  """
  def capitalize_as_title(source) do
    source
    |> prepare_string_for_title()
    |> Enum.with_index()
    |> Enum.map(fn
      {part, 0} ->
        part |> String.capitalize()

      {part, _} ->
        part
    end)
    |> Enum.join(" ")
  end

  @doc """
  Transforms a source string into a taxonomy title.

  ## Examples

      iex> LiveMarkdown.Content.Utils.capitalize_as_taxonomy_name("post-about-art")
      "Post About Art"

      iex> LiveMarkdown.Content.Utils.capitalize_as_taxonomy_name("3d-models")
      "3D Models"

      iex> LiveMarkdown.Content.Utils.capitalize_as_taxonomy_name("Products: wood-chairs")
      "Products: Wood Chairs"

      iex> LiveMarkdown.Content.Utils.capitalize_as_taxonomy_name("products-above-$300mm")
      "Products Above $300MM"
  """
  def capitalize_as_taxonomy_name(source) do
    source
    |> prepare_string_for_title()
    |> Enum.map(&String.capitalize/1)
    |> Enum.map(fn part ->
      if String.match?(part, ~r/^([0-9]|\$)/) do
        part |> String.upcase()
      else
        part
      end
    end)
    |> Enum.join(" ")
  end

  defp prepare_string_for_title(source) do
    source
    |> String.trim()
    |> String.replace("-", " ")
    |> String.replace("_", " ")
    |> String.split(" ")
  end

  def is_date?(date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def is_datetime?(date) do
    case DateTime.from_iso8601(date) do
      {:ok, _, _} -> true
      _ -> false
    end
  end

  @doc """
  Convert map string keys to :atom keys
  """
  def atomize_keys(nil), do: nil

  # Structs don't do enumerable and anyway the keys are already
  # atoms
  def atomize_keys(struct = %{__struct__: _}) do
    struct
  end

  def atomize_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {maybe_to_atom(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  # Walk the list and atomize the keys of
  # of any map members
  def atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  def atomize_keys(not_a_map) do
    not_a_map
  end

  def maybe_to_atom(val) when is_binary(val), do: String.to_atom(val)
  def maybe_to_atom(val) when is_atom(val), do: val

  def atomize_value_if_found(map, key) when is_map(map) do
    case Map.get(map, key) do
      nil -> map
      val -> map |> Map.put(key, val |> maybe_to_atom())
    end
  end
end
