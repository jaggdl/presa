# frozen_string_literal: true

require "test_helper"

class JellyfinGetSeasonsToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "get_seasons"
  end

  test "hits the series seasons endpoint with a user id" do
    tool, fake = expose_jellyfin_tool("get_seasons")
    tool.call(series_id: "abc123")

    path = fake.last_path
    assert_includes path, "/Shows/abc123/Seasons?"
    assert_includes path, "userId="
  end

  test "includes fields when given" do
    tool, fake = expose_jellyfin_tool("get_seasons")
    tool.call(series_id: "abc123", fields: "Overview,DateCreated")

    assert_includes fake.last_path, "fields=Overview%2CDateCreated"
  end
end
