# frozen_string_literal: true

require "test_helper"

class JellyfinSearchUserMediaToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "search_user_media"
  end

  test "hits the user items endpoint with the query" do
    tool, fake = expose_jellyfin_tool("search_user_media")
    tool.call(query: "star")

    path = fake.last_path
    assert_includes path, "/Users/"
    assert_includes path, "/Items?"
    assert_includes path, "searchTerm=star"
    assert_includes path, "limit=20"
  end

  test "includes item type filter when given" do
    tool, fake = expose_jellyfin_tool("search_user_media")
    tool.call(query: "star", include_item_types: "Movie,Series")

    assert_includes fake.last_path, "includeItemTypes=Movie%2CSeries"
  end
end
