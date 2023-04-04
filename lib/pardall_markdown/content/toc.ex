defmodule PardallMarkdown.Content.TOC do
  defmodule Tree do
    defstruct branches: []
  end

  defmodule Branch do
    defstruct level: 1,
      header: 1000,
      branches: [],
      leaves: []
  end

  defmodule Link do
    defstruct id: "",
      header: 1,
      parent_slug: "",
      title: ""
  end

  defmodule Leaf do
    defstruct level: 1,
      header: 1000,
      link: %Link{}
  end

  def generate(toc_links) do
    toc_links
    |> append()
  end

  def append(links \\ [], tree \\ %Tree{}, curr_top_branch \\ nil, curr_branch \\ nil)

  def append([], tree, _curr_top_branch, curr_branch) do
    # TODO: append branch to top branch if they are different and append top branch to tree
    put_in(tree.branches, tree.branches ++ [curr_branch])
  end

  def append([%Link{} = link|links], %Tree{branches: []} = tree, curr_top_branch, _curr_branch) do
    level = 1
    curr_branch = %Branch{
      level: level,
      header: link.header,
      leaves: [%Leaf{
        level: level,
        header: link.header,
        link: link
      }]
    }

    links
    |> append(tree, curr_top_branch, curr_branch)
  end

  def append([%Link{header: link_level} = link|links], tree, curr_top_branch, %Branch{header: branch_header} = curr_branch)
  when link_level == branch_header do
    curr_branch = put_in(curr_branch.leaves, curr_branch.leaves ++ [%Leaf{
      level: curr_branch.level,
      header: link.header,
      link: link
    }])

    links
    |> append(tree, curr_top_branch, curr_branch)
  end
end

# [
#   %{
#     id: "#header-2-level-1",
#     level: 2,
#     parent_slug: "/headers",
#     title: "Header 2, Level 1"
#   },
#   %{
#     id: "#header-3-level-2",
#     level: 3,
#     parent_slug: "/headers",
#     title: "Header 3, Level 2"
#   },
#   %{
#     id: "#header-4-level-3",
#     level: 4,
#     parent_slug: "/headers",
#     title: "Header 4, Level 3"
#   },
#   %{
#     id: "#header-2-level-1-1",
#     level: 2,
#     parent_slug: "/headers",
#     title: "Header 2, Level 1"
#   },
#   %{
#     id: "#header-1-level-1",
#     level: 1,
#     parent_slug: "/headers",
#     title: "Header 1, Level 1"
#   },
#   %{
#     id: "#header-4-level-2",
#     level: 4,
#     parent_slug: "/headers",
#     title: "Header 4, Level 2"
#   },
#   %{
#     id: "#header-3-level-2-1",
#     level: 3,
#     parent_slug: "/headers",
#     title: "Header 3, Level 2"
#   }
# ]
