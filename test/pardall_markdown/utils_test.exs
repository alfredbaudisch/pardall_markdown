defmodule InstaMarkdown.ContentUtilsTest do
  use ExUnit.Case, async: true
  alias PardallMarkdown.Content.Utils

  @moduletag :content
  @moduletag :utils

  doctest PardallMarkdown.Content.Utils

  test "path is created recursively" do
    if File.exists?("./test/mycontent/markdown"), do: File.rmdir!("./test/mycontent/markdown")
    if File.exists?("./test/mycontent"), do: File.rmdir!("./test/mycontent")

    Utils.recursively_create_path!("./test/mycontent/markdown")
    assert File.exists?("./test/mycontent/markdown")

    File.rmdir!("./test/mycontent/markdown")
    File.rmdir!("./test/mycontent")
  end
end
