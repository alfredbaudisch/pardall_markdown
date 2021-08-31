defmodule LiveMarkdownWeb.PageLive do
  use LiveMarkdownWeb, :live_view
  alias LiveMarkdown.Content.Repository

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      LiveMarkdownWeb.Endpoint.subscribe("content")
    end

    {:ok, assign(socket, posts: Repository.get_all_published()) |> assign_page_title()}
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

  @impl true
  def handle_info(%{event: "post_events", payload: payload}, socket) do
    if Enum.find(payload, fn
         {_, :deleted} -> true
         _ -> false
       end) do
      {:noreply, assign(socket, posts: Repository.get_all_published())}
    else
      {:noreply, socket}
    end
  end

  defp assign_page_title(socket),
    do: socket |> assign(:page_title, site_name())
end
