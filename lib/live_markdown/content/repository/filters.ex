defmodule LiveMarkdown.Content.Repository.Filters do
  def filter_by_is_published(posts), do: posts |> Enum.filter(& &1.is_published)
  def sort_by_published_date(posts), do: posts |> Enum.sort_by(& &1.date, {:desc, DateTime})
end
