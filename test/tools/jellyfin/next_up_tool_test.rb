# frozen_string_literal: true

require "test_helper"

class JellyfinNextUpToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "next_up"
  end

  test "hits the shows next-up endpoint" do
    tool, fake = expose_jellyfin_tool("next_up")
    tool.call(limit: 5)

    path = fake.last_path
    assert_includes path, "/Shows/NextUp?"
    assert_includes path, "limit=5"
  end

  test "includes a series id when given" do
    tool, fake = expose_jellyfin_tool("next_up")
    tool.call(series_id: "abc123")

    assert_includes fake.last_path, "seriesId=abc123"
  end
end
