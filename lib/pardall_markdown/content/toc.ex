defmodule PardallMarkdown.Content.TOC do
  defmodule Tree do
    defstruct branches: []
  end

  defmodule Branch do
    defstruct level: 1,
      real_level: 1000,
      branches: [],
      leaves: []
  end

  defmodule Leaf do
    defstruct level: 1,
      real_level: 1000,
      link: %{}
  end

  def append(%Tree{branches: []}, real_level, link) do
    %Tree{branches: [%Branch{
      level: 1,
      real_level: real_level,
      leaves: [%Leaf{
        level: 1,
        real_level: real_level,
        link: link
      }]
    }]}
  end
end
