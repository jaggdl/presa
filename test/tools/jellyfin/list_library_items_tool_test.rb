# frozen_string_literal: true

require "test_helper"

class JellyfinListLibraryItemsToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "list_library_items"
  end

  test "hits the library items endpoint with a user id" do
    tool, fake = expose_jellyfin_tool("list_library_items")
    tool.call(library_id: "lib-1")

    path = fake.last_path
    assert_includes path, "/Users/user-1/Items?"
    assert_includes path, "userId=user-1"
    assert_includes path, "recursive=true"
    assert_includes path, "parentId=lib-1"
  end

  test "includes item types and limit when given" do
    tool, fake = expose_jellyfin_tool("list_library_items")
    tool.call(item_types: "Movie,Series", limit: 10)

    path = fake.last_path
    assert_includes path, "/Users/user-1/Items?"
    assert_includes path, "includeItemTypes=Movie%2CSeries"
    assert_includes path, "limit=10"
  end
end
