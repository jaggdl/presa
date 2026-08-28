# frozen_string_literal: true

require "test_helper"

class GmailSendMessageToolTest < ActiveSupport::TestCase
  include GmailToolTestHelper

  test "is exposed for gmail services" do
    kinds = ApplicationTool.expose_for(services(:gmail)).map(&:kind)
    assert_includes kinds, "send_message"
  end

  test "sends a base64-encoded message with an auth header" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/gmail/v1/users/me/messages/send") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.body)
        decoded = Base64.urlsafe_decode64(body["raw"])
        assert_includes decoded, "To: friend@example.com"
        assert_includes decoded, "Subject: Hi"
        assert_includes decoded, "Just saying hello"
        gmail_json_response({ id: "sent-1" })
      end
    end

    result = tool.call(to: "friend@example.com", subject: "Hi", body: "Just saying hello")
    assert_equal "sent-1", result["id"]
  end

  test "encodes non-ascii subjects as an RFC 2047 encoded-word" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/gmail/v1/users/me/messages/send") do |env|
        body = JSON.parse(env.body)
        decoded = Base64.urlsafe_decode64(body["raw"])
        assert_includes decoded, "Subject: =?UTF-8?B?VmVyaWZpY2FjacOz"
        gmail_json_response({ id: "sent-2" })
      end
    end

    result = tool.call(to: "friend@example.com", subject: "Verificación", body: "Hola")
    assert_equal "sent-2", result["id"]
  end
end
