# frozen_string_literal: true

require "test_helper"

class JellyfinSimilarItemsToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "similar_items"
  end

  test "hits the similar items endpoint with the item id and user id" do
    tool, fake = expose_jellyfin_tool("similar_items")
    tool.call(item_id: "abc123")

    path = fake.last_path
    assert_includes path, "/Items/abc123/Similar?"
    assert_includes path, "userId=user-1"
  end

  test "includes a limit when given" do
    tool, fake = expose_jellyfin_tool("similar_items")
    tool.call(item_id: "abc123", limit: 5)

    path = fake.last_path
    assert_includes path, "limit=5"
  end
end
