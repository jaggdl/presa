# frozen_string_literal: true

require "test_helper"

class JellyfinGetItemDetailsToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "get_item_details"
  end

  test "hits the user item endpoint with the item id" do
    tool, fake = expose_jellyfin_tool("get_item_details")
    tool.call(item_id: "abc123")

    path = fake.last_path
    assert_includes path, "/Users/"
    assert_includes path, "/Items/abc123?"
  end

  test "includes fields and a user id when given" do
    tool, fake = expose_jellyfin_tool("get_item_details")
    tool.call(item_id: "abc123", user_id: "user1", fields: "Overview,Genres")

    path = fake.last_path
    assert_includes path, "/Users/user1/Items/abc123?"
    assert_includes path, "fields=Overview%2CGenres"
  end
end
