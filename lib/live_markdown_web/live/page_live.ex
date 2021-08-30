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
      |> Enum.reduce(%{}, fn
        %{id: id, is_published: true} = post, posts ->
          Map.put(posts, id, post)

        _, posts ->
          posts
      end)

    {:ok, assign(socket, posts: posts) |> assign_page_title()}
  end

  @impl true
  def handle_info(
        %{event: "post_updated", payload: %{id: id, is_published: is_published} = content},
        socket
      ) do
    posts =
      if is_published,
        do: Map.put(socket.assigns[:posts], id, content),
        else: Map.delete(socket.assigns[:posts], id)

    {:noreply, socket |> assign(:posts, posts)}
  end

  defp assign_page_title(socket),
    do: socket |> assign(:page_title, site_name())
end
