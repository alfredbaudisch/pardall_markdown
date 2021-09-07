defmodule LiveMarkdown.Content.Cache.Item do
  @type t :: %__MODULE__{
          type: :post | :link,
          value: map
        }
  defstruct [:type, :value]

  def new_post(value), do: %__MODULE__{type: :post, value: value}
  def new_link(value), do: %__MODULE__{type: :link, value: value}
end
