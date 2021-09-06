defmodule LiveMarkdownWeb.Live.SinglePost do
  use LiveMarkdownWeb, :live_view
  alias LiveMarkdown.{Post, Taxonomy}

  def mount(%{"slug" => slug}, _session, socket) do
    slug =
      slug
      |> slug_params_to_slug()

    post = Repository.get_by_slug!(slug)

    if connected?(socket) do
      Endpoint.subscribe("post_" <> slug)
    end

    {:ok, socket |> assign(:post, post) |> assign_page_title(post)}
  end

  def handle_info(%{event: "post_updated", payload: content}, socket) do
    {:noreply, socket |> assign(:post, content) |> assign_page_title(content)}
  end

  def handle_info(%{event: "post_deleted", payload: _}, socket) do
    {:noreply, socket |> put_flash(:error, "This post has been deleted or moved to another URL.")}
  end

  defp slug_params_to_slug(slug), do: "/" <> Enum.join(slug, "/")

  defp assign_page_title(socket, %Post{title: title}),
    do: socket |> assign(:page_title, compose_page_title(title))
end
