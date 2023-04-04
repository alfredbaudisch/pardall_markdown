defmodule PardallMarkdown.Utils.StructUtils do
  def struct_to_map([]), do: []

  def struct_to_map([_h|_t] = list) do
    Enum.map(list, &struct_to_map/1)
  end

  def struct_to_map(item) when is_struct(item) do
    item
    |> Map.from_struct()
    |> navigate_item()
  end

  def struct_to_map(item) when is_map(item) do
    item
    |> navigate_item()
  end

  defp navigate_item(item) do
    item
    |> Enum.map(fn
      {k, v} when is_list(v) ->
        {k, v |> struct_to_map()}
      {k, v} -> {k, v}
    end)
    |> Enum.into(%{})
  end
end
