defmodule PardallMarkdown.Content.Utils do
  @taxonomy_index_file "_index.md"
  @root_path Application.compile_env!(:pardall_markdown, [PardallMarkdown.Content, :root_path])
  @static_assets_folder_name Application.compile_env!(:pardall_markdown, [
                               PardallMarkdown.Content,
                               :static_assets_folder_name
                             ])

  def root_path, do: @root_path
  def static_assets_folder_name, do: @static_assets_folder_name
  def static_assets_path, do: Path.join(root_path(), static_assets_folder_name())

  def is_path_from_static_assets?(path), do: String.starts_with?(path, static_assets_path())

  def remove_root_path(path), do: path |> String.replace(root_path(), "")

  def taxonomy_index_file, do: @taxonomy_index_file
  def is_index_file?(path), do: Path.basename(path) == taxonomy_index_file()

  def default_sort_by, do: :date
  def default_sort_order, do: :desc
  def default_position, do: 100_000

  @doc """
  Splits a path into a tree of categories, containing both readable category names
  and slugs for all categories in the hierarchy. The categories list is indexed from the
  topmost to the lowermost in the hiearchy, example: Games > PC > RPG.

  Also returns the level in the tree in which the category can be found,
  as well as all parent categories slugs recursively, where `level: 0` is
  for root pages (i.e. no category).

  TODO: For the initial purpose of this project, this solution is ok,
  but eventually let's implement it with a "real" tree or linked list.

  ## Examples

      iex> PardallMarkdown.Content.Utils.extract_categories_from_path("/blog/art/3d-models/post.md")
      [
        %{title: "Blog", slug: "/blog", level: 0, parents: ["/"]},
        %{
          title: "Art",
          slug: "/blog/art",
          level: 1,
          parents: ["/", "/blog"]
        },
        %{
          title: "3D Models",
          slug: "/blog/art/3d-models",
          level: 2,
          parents: ["/", "/blog", "/blog/art"]
        }
      ]

      iex> PardallMarkdown.Content.Utils.extract_categories_from_path("/blog/post.md")
      [%{title: "Blog", slug: "/blog", level: 0, parents: ["/"]}]

      iex> PardallMarkdown.Content.Utils.extract_categories_from_path("/post.md")
      [%{title: "Home", slug: "/", level: 0, parents: ["/"]}]
  """
  def extract_categories_from_path(full_path) do
    full_path
    |> String.replace(Path.basename(full_path), "")
    |> do_extract_categories()
  end

  # Root / Page
  defp do_extract_categories("/"), do: [%{title: "Home", slug: "/", level: 0, parents: ["/"]}]
  # Path with category and possibly, hierarchy
  defp do_extract_categories(path) do
    final_slug = extract_slug_from_path(path)
    slug_parts = final_slug |> String.split("/")

    path
    |> String.replace(~r/^\/(.*)\/$/, "\\1")
    |> String.split("/")
    |> Enum.with_index()
    |> Enum.map(fn {part, pos} ->
      slug =
        slug_parts
        |> Enum.take(pos + 2)
        |> Enum.join("/")

      parents =
        for idx <- 0..pos do
          slug_parts |> Enum.take(idx + 1) |> Enum.join("/")
        end
        |> Enum.map(fn
          "" -> "/"
          parent -> parent
        end)

      category = part |> capitalize_as_taxonomy_name()

      %{title: category, slug: slug, level: pos, parents: parents}
    end)
  end

  @doc """
  ## Examples

      iex> PardallMarkdown.Content.Utils.extract_slug_from_path("/blog/art/3d/post.md")
      "/blog/art/3d/post"

      iex> PardallMarkdown.Content.Utils.extract_slug_from_path("/blog/My new Project.md")
      "/blog/my-new-project"

      iex> PardallMarkdown.Content.Utils.extract_slug_from_path("/blog/_index.md")
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

      iex> PardallMarkdown.Content.Utils.extract_title_from_path("/blog/art/3d/post-about-art.md")
      "Post about art"

      iex> PardallMarkdown.Content.Utils.extract_title_from_path("/blog/My new Project.md")
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

      iex> PardallMarkdown.Content.Utils.capitalize_as_title("post-about-art")
      "Post about art"

      iex> PardallMarkdown.Content.Utils.capitalize_as_title("My new Project")
      "My new Project"

      iex> PardallMarkdown.Content.Utils.capitalize_as_title("2d 3D 4d-art: this is bugged, 3d should've been preserved as 3d not separate strings")
      "2d 3D 4d art: this is bugged, 3d should've been preserved as 3d not separate strings"

      iex> PardallMarkdown.Content.Utils.capitalize_as_title("Some Startup plans to expand quantum Platform of the Platforms with $500M investment")
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

      iex> PardallMarkdown.Content.Utils.capitalize_as_taxonomy_name("post-about-art")
      "Post About Art"

      iex> PardallMarkdown.Content.Utils.capitalize_as_taxonomy_name("3d-models")
      "3D Models"

      iex> PardallMarkdown.Content.Utils.capitalize_as_taxonomy_name("Products: wood-chairs")
      "Products: Wood Chairs"

      iex> PardallMarkdown.Content.Utils.capitalize_as_taxonomy_name("products-above-$300mm")
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

  def maybe_to_atom(val) when is_binary(val), do: String.to_atom(val)
  def maybe_to_atom(val) when is_atom(val), do: val

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
end
