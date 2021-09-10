defmodule LiveMarkdownWeb.Live.Index do
  use LiveMarkdownWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("live_markdown")
    end

    {:ok, socket |> load_content()}
  end

  defp load_content(socket) do
    socket
    |> assign(
      posts: Repository.get_all_published() |> sort_by_published_date(),
      content_tree: Repository.get_content_tree(),
      taxonomy_tree: Repository.get_taxonomy_tree(),
      docs_tree: Repository.get_content_tree("/docs")
    )
    |> assign_page_title()
  end

  @impl true
  def handle_info(%{event: "content_reloaded", payload: _}, socket) do
    {:noreply, socket |> load_content()}
  end

  defp assign_page_title(socket),
    do: socket |> assign(:page_title, site_name())
end
