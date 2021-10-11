defmodule PardallMarkdown.RepositoryProviders.Git do
  @moduledoc """
  This implementation closely follows the implementation found in:
  https://github.com/meddle0x53/blogit/blob/master/lib/blogit/settings.ex
  Many thanks to @meddle0x53 for this!
  """
  require Logger

  @behaviour PardallMarkdown.RepositoryProvider

  @repository_url Application.get_env(:pardall_markdown, :repository_url, "")
  @local_path @repository_url
                |> String.split("/")
                |> List.last()
                |> String.trim_trailing(".git")

  # Callbacks

  def repository do
    repo = git_repository()

    case Git.pull(repo) do
      {:ok, msg} ->
        Logger.info("Pulling from git repository #{msg}")

      {_, error} ->
        Logger.error("Error while pulling from git repository #{inspect(error)}")
    end

    repo
  end

  def fetch(repo) do
    Logger.info("Fetching data from #{@repository_url}")

    case Git.fetch(repo) do
      {:error, _} ->
        {:no_updates}

      {:ok, ""} ->
        {:no_updates}

      {:ok, _} ->
        updates =
          repo
          |> Git.diff!(["--name-only", "HEAD", "origin/master"])
          |> String.split("\n", trim: true)
          |> Enum.map(&String.trim/1)

        Logger.info("There are new updates, pulling them.")
        Git.pull!(repo)

        {:updates, updates}
    end
  end

  def local_path, do: @local_path

  def list_files(folder \\ Settings.posts_folder()) do
    path = Path.join(@local_path, folder)
    size = byte_size(path) + 1

    path
    |> recursive_ls()
    |> Enum.map(fn <<_::binary-size(size), rest::binary>> -> rest end)
  end

  def file_in?(file), do: File.exists?(Path.join(@local_path, file))

  def file_info(repository, file_path) do
    %{
      author: file_author(repository, file_path),
      created_at: file_created_at(repository, file_path),
      updated_at: file_updated_at(repository, file_path)
    }
  end

  def read_file(file_path, folder \\ "") do
    local_path() |> Path.join(folder) |> Path.join(file_path) |> File.read()
  end

  # Private

  defp log(repository, args), do: Git.log!(repository, args)

  defp first_in_log(repository, args) do
    repository
    |> log(args)
    |> String.split("\n")
    |> List.first()
    |> String.trim()
  end

  defp recursive_ls(path) do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        path
        |> File.ls!()
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&recursive_ls/1)
        |> Enum.concat()

      true ->
        []
    end
  end

  defp git_repository do
    Logger.info("Cloning repository #{@repository_url}")

    case Git.clone(@repository_url) do
      {:ok, repo} -> repo
      {:error, Git.Error} -> Git.new(@local_path)
    end
  end

  defp file_author(repository, file_name) do
    first_in_log(repository, ["--reverse", "--format=%an", file_name])
  end

  defp file_created_at(repository, file_name) do
    case first_in_log(repository, ["--reverse", "--format=%ci", file_name]) do
      "" -> DateTime.to_iso8601(DateTime.utc_now())
      created_at -> created_at
    end
  end

  defp file_updated_at(repository, file_name) do
    case repository |> log(["-1", "--format=%ci", file_name]) |> String.trim() do
      "" -> DateTime.to_iso8601(DateTime.utc_now())
      updated_at -> updated_at
    end
  end
end
