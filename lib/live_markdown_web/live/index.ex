defmodule LiveMarkdownWeb.Live.Index do
  use LiveMarkdownWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("content")
    end

    {:ok,
     assign(socket,
       posts: Repository.get_all_published(),
       taxonomy_tree: Repository.get_taxonomy_tree()
     )
     |> assign_page_title()}
  end

  @impl true
  def handle_info(%{event: "post_created", payload: _}, socket) do
    {:noreply, socket |> assign(:posts, Repository.get_all_published())}
  end

  @impl true
  def handle_info(%{event: "post_updated", payload: %{id: id} = post}, socket) do
    # Isn't it easier to just reload all posts? `Repository.get_all_published()`
    posts =
      socket.assigns[:posts]
      |> Enum.map(fn
        %{id: post_id} when post_id == id -> post
        i_post -> i_post
      end)
      |> Repository.Filters.filter_by_is_published()
      |> Repository.Filters.sort_by_published_date()

    {:noreply, socket |> assign(:posts, posts)}
  end

  @impl true
  def handle_info(%{event: "post_events", payload: payload}, socket) do
    # One or more posts were deleted, reload all posts
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
