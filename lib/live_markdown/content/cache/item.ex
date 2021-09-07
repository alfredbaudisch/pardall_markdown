defmodule LiveMarkdown.Content.Cache.Item do
  @enforce_keys [:type, :value]

  @type t :: %__MODULE__{
          type: :post | :taxonomy,
          value: map
        }
  defstruct [:type, :value]

  def new_post(value), do: %__MODULE__{type: :post, value: value}
  def new_taxonomy(value), do: %__MODULE__{type: :taxonomy, value: value}
end
