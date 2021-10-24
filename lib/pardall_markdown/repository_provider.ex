defmodule PardallMarkdown.RepositoryProvider do
  @moduledoc """
  This implementation closely follows the implementation found in:
  https://github.com/meddle0x53/blogit/blob/master/lib/blogit/repository_provider.ex
  Many thanks to @meddle0x53 for this!
  """

  @type repository :: term
  @type provider :: module
  @type fetch_result :: {:no_updates} | {:updates, [String.t()]}

  @type t :: %__MODULE__{repo: repository, provider: provider}
  @enforce_keys :provider
  defstruct [:repo, :provider]

   @doc """
  Invoked to get a representation value of the repository the provider manages.
  The actual data represented by this struct should be updated to its
  newest version first.
  If for example the repository is remote, all the files in it should be
  downloaded so their most recent versions are accessible.
  This structure can be passed to other callbacks in order to manage files
  in the repository.
  """
  @callback repository() :: repository

  @doc """
  Invoked to update the data represented by the given `repository` to its most
  recent version.
  If, for example the repository is remote, all the files in it should be
  downloaded so their most recent versions are accessible.
  Returns the path to the changed files in the form of the tuple
  `{:updates, list-of-paths}`. These paths should be paths to deleted, updated
  or newly created files.
  """
  @callback fetch(repository) :: fetch_result

  @doc """
  Invoked to get the path to the locally downloaded data. If the repository
  is remote, it should have local copy or something like that.
  """
  @callback local_path() :: String.t()
end
