defmodule LiveMarkdownWeb.Live.PostSingle do
  use LiveMarkdownWeb, :live_view
  alias LiveMarkdown.Post

  def mount(%{"slug" => slug}, _session, socket) do
    slug =
      slug
      |> slug_params_to_slug()

    if connected?(socket) do
      Endpoint.subscribe("post_" <> slug)
    end

    post = Repository.get_by_slug!(slug)

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
