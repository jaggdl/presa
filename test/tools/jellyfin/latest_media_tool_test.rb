# frozen_string_literal: true

require "test_helper"

class JellyfinLatestMediaToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "latest_media"
  end

  test "hits the latest items endpoint" do
    tool, fake = expose_jellyfin_tool("latest_media")
    tool.call(limit: 5)

    path = fake.last_path
    assert_includes path, "/Users/"
    assert_includes path, "/Items/Latest?"
    assert_includes path, "limit=5"
  end
end
