# frozen_string_literal: true

require "test_helper"

class JellyfinResumeItemsToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    kinds = ApplicationTool.expose_for(services(:jellyfin)).map(&:kind)
    assert_includes kinds, "resume_items"
  end

  test "hits the resume endpoint with a resolved user id" do
    tool, fake = expose_jellyfin_tool("resume_items")
    tool.call(limit: 5)

    path = fake.last_path
    assert_includes path, "/Items/Resume?"
    assert_includes path, "userId=user-1"
    assert_includes path, "limit=5"
  end
end
