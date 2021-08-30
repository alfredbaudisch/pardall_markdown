defmodule LiveMarkdownWeb.Live.PostSingle do
  use LiveMarkdownWeb, :live_view
  alias LiveMarkdown.Content.Repository

  def mount(%{"slug" => slug}, _session, socket) do
    slug =
      slug
      |> slug_params_to_slug()

    if connected?(socket) do
      LiveMarkdownWeb.Endpoint.subscribe("post_" <> slug)
    end

    {:ok, socket |> assign(:post, Repository.get_by_slug!(slug))}
  end

  def handle_info(%{event: "post_updated", payload: content}, socket) do
    {:noreply, socket |> assign(:post, content)}
  end

  defp slug_params_to_slug(slug), do: "/" <> Enum.join(slug, "/")
end
