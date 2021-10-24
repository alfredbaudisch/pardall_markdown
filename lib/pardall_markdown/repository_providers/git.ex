defmodule PardallMarkdown.RepositoryProviders.Git do
  @moduledoc """
  This implementation is based on the implementation found in:
  https://github.com/meddle0x53/blogit/blob/master/lib/blogit/settings.ex
  Many thanks to @meddle0x53 for this!
  """
  require Logger

  @behaviour PardallMarkdown.RepositoryProvider

  @repository_url Application.get_env(:pardall_markdown, PardallMarkdown.Content)[
    :remote_repository_url
  ]
  @local_path PardallMarkdown.Content.Utils.root_path()

  # Callbacks
  @impl true
  def repository do
    repo = git_repository()

    case Git.pull(repo) do
      {:ok, msg} ->
        Logger.info("Pulling from git repository #{msg}")

      # Crash in case of unstaged changes
      {_, %Git.Error{
        args: [], code: 128, command: "pull",
        message: "error: cannot pull with rebase: You have unstaged changes.\nerror: please commit or stash them.\n" = message
      }} ->
        raise message

      {_, error} ->
        Logger.error("Error while pulling from git repository #{inspect(error)}")
    end

    repo
  end

  @impl true
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

  @impl true
  def local_path, do: @local_path

  # Private
  defp git_repository do
    if repository_exists?() do
      Git.new(@local_path)
    else
      case Git.clone([@repository_url, @local_path]) do
        {:ok, repo} ->
          Logger.info("Cloning repository #{@repository_url}, into #{@local_path}")
          repo
        {:error, %Git.Error{}} ->
          Git.new(@local_path)
      end
    end
  end

  defp repository_exists?, do: File.exists?(Path.join(@local_path, ".git"))
end
