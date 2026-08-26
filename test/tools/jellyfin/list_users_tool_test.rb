# frozen_string_literal: true

require "test_helper"

class JellyfinListUsersToolTest < ActiveSupport::TestCase
  include JellyfinToolTestHelper

  test "is exposed for jellyfin services" do
    assert_includes ApplicationTool.expose_for(services(:jellyfin)).map(&:kind), "list_users"
  end

  test "hits the users endpoint and returns the user list" do
    tool, fake = expose_jellyfin_tool("list_users")
    tool.call

    assert_includes fake.last_path, "/Users"
  end
end
