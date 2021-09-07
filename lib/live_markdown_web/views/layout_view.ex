defmodule LiveMarkdownWeb.LayoutView do
  use LiveMarkdownWeb, :view

  def taxonomy_tree(tree) do
  end

  def taxonomy_tree([taxonomy | tail], all, level, previous_level) when level > previous_level do
    # nest new level
  end

  def taxonomy_tree([taxonomy | tail], all, level, previous_level) when level < previous_level do
    # go up (previous_level - level) levels, closing nest(s)
  end

  def taxonomy_tree([taxonomy | tail], all, level, previous_level) when level == previous_level do
    # same level
  end
end
