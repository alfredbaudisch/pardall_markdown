defmodule LiveMarkdownWeb.PageLive do
  use LiveMarkdownWeb, :live_view
  alias LiveMarkdown.Content.Repository

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      LiveMarkdownWeb.Endpoint.subscribe("content")
    end

    posts =
      Repository.get_all()
      |> Enum.reduce(%{}, fn %{id: id} = post, posts ->
        Map.put(posts, id, post)
      end)

    {:ok, assign(socket, query: "", results: %{}, posts: posts)}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  @impl true
  def handle_info(%{event: "post_updated", payload: %{id: id} = content}, socket) do
    posts = Map.put(socket.assigns[:posts], id, content)

    {:noreply, socket |> assign(:posts, posts)}
  end

  defp search(query) do
    if not LiveMarkdownWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end
end
