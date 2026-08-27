# frozen_string_literal: true

require "test_helper"

class GmailGetMessageToolTest < ActiveSupport::TestCase
  include GmailToolTestHelper

  test "is exposed for gmail services" do
    kinds = ApplicationTool.expose_for(services(:gmail)).map(&:kind)
    assert_includes kinds, "get_message"
  end

  test "fetches a message by id with an auth header" do
    tool = expose_gmail_tool("get_message") do |stub|
      stub.get("/gmail/v1/users/me/messages/abc123") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        gmail_json_response({ id: "abc123", snippet: "Hello" })
      end
    end

    result = tool.call(id: "abc123")
    assert_equal "abc123", result["id"]
  end
end
