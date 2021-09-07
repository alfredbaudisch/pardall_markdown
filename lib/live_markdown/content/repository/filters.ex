defmodule LiveMarkdown.Content.Repository.Filters do
  def filter_by_is_published(posts), do: posts |> Enum.filter(& &1.is_published)
  def sort_by_published_date(posts), do: posts |> Enum.sort_by(& &1.date, {:desc, DateTime})
  def sort_by_title(posts), do: posts |> Enum.sort_by(& &1.title)
  def sort_by_slug(items), do: items |> Enum.sort_by(& &1.slug)

  def sort_by_map_key(%{} = items), do: items |> Enum.sort_by(fn {key, _} -> key end)

  def sort_level_one_taxonomies_by_name(taxonomies) do
    taxonomies
    |> Enum.sort_by(
      fn %{level: level, title: title} -> {level, title} end,
      fn
        {1, title}, {1, previous_title} ->
          title <= previous_title

        el1, el2 ->
          el1 <= el2
      end
    )
  end
end
