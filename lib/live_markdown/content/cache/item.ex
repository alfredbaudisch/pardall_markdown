defmodule LiveMarkdown.Content.Cache.Item do
  @enforce_keys [:type, :value]
  defstruct [:type, :value]

  def new_post(value), do: %__MODULE__{type: :post, value: value}
  def new_taxonomy(value), do: %__MODULE__{type: :taxonomy, value: value}
end
