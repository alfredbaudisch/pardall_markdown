defmodule LiveMarkdownWeb.PlugRedirectTrailingSlash do
  def init(opts), do: opts

  def call(%{request_path: request_path} = conn, :without) when request_path != "/" do
    if String.ends_with?(request_path, "/") do
      conn
      |> redirect(String.slice(request_path, 0..-2))
    else
      conn
    end
  end

  def call(%{request_path: request_path} = conn, :with) when request_path != "/" do
    if not String.ends_with?(request_path, "/") do
      conn
      |> redirect(request_path <> "/")
    else
      conn
    end
  end

  def call(conn, _), do: conn

  defp redirect(conn, path) do
    conn
    |> Plug.Conn.put_status(301)
    |> Phoenix.Controller.redirect(to: path)
    |> Plug.Conn.halt()
  end
end
