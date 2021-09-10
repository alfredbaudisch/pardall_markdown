defmodule KodaMarkdownWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use KodaMarkdownWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import KodaMarkdownWeb.ConnCase

      alias KodaMarkdownWeb.Router.Helpers, as: Routes

      import KodaMarkdownWeb.ContentHelpers

      # The default endpoint for testing
      @endpoint KodaMarkdownWeb.Endpoint
    end
  end

  setup _tags do
    Application.ensure_all_started(:koda_markdown)
    # wait the Markdown content to be parsed and built
    Process.sleep(100)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
