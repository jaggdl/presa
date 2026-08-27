# frozen_string_literal: true

require "test_helper"

class GmailListMessagesToolTest < ActiveSupport::TestCase
  include GmailToolTestHelper

  test "is exposed for gmail services" do
    kinds = ApplicationTool.expose_for(services(:gmail)).map(&:kind)
    assert_includes kinds, "list_messages"
  end

  test "lists messages with default limit and an auth header" do
    tool = expose_gmail_tool("list_messages") do |stub|
      stub.get("/gmail/v1/users/me/messages") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        gmail_json_response({ messages: [ { id: "msg-1" } ], resultSizeEstimate: 20 })
      end
    end

    result = tool.call(query: nil, limit: nil)
    assert_equal [ { "id" => "msg-1" } ], result["messages"]
  end

  test "passes the query and limit as params" do
    tool = expose_gmail_tool("list_messages") do |stub|
      stub.get("/gmail/v1/users/me/messages") do |env|
        assert_equal "is:unread", env.params["q"]
        assert_equal "50", env.params["maxResults"].to_s
        gmail_json_response({ messages: [] })
      end
    end

    tool.call(query: "is:unread", limit: 50)
  end
end
