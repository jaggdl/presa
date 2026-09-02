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

  test "attaches base64 files as multipart MIME parts" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/upload/gmail/v1/users/me/messages/send") do |env|
        assert_equal "message/rfc822", env.request_headers["Content-Type"]
        assert_equal "media", env.params["uploadType"]
        assert_includes env.body, "Content-Type: multipart/mixed; boundary="
        assert_includes env.body, "Content-Type: text/plain; charset=UTF-8"
        assert_includes env.body, "Content-Type: application/pdf"
        assert_includes env.body, 'Content-Disposition: attachment; filename="report.pdf"'
        assert_includes env.body, "Content-Transfer-Encoding: base64"
        assert_includes env.body, Base64.strict_encode64("PDF_BYTES")
        assert_includes env.body, "Body text"
        gmail_json_response({ id: "sent-3" })
      end
    end

    result = tool.call(
      to: "friend@example.com",
      subject: "Report",
      body: "Body text",
      attachments: [
        { filename: "report.pdf", content: Base64.strict_encode64("PDF_BYTES"), mime_type: "application/pdf" }
      ]
    )
    assert_equal "sent-3", result["id"]
  end

  test "infers the attachment MIME type from the filename extension" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/upload/gmail/v1/users/me/messages/send") do |env|
        assert_includes env.body, "Content-Type: application/pdf"
        gmail_json_response({ id: "sent-4" })
      end
    end

    result = tool.call(
      to: "friend@example.com",
      subject: "Report",
      body: "Body",
      attachments: [ { filename: "report.pdf", content: Base64.strict_encode64("x") } ]
    )
    assert_equal "sent-4", result["id"]
  end

  test "raises when attachment content is not valid base64" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/upload/gmail/v1/users/me/messages/send") { |_env| gmail_json_response({ id: "e" }) }
    end

    error = assert_raises(ArgumentError) do
      tool.call(
        to: "friend@example.com",
        subject: "Report",
        body: "Body",
        attachments: [ { filename: "report.pdf", content: "not base64!!!" } ]
      )
    end
    assert_match(/valid base64/, error.message)
  end

  test "sends oversized plain messages to the media upload endpoint" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/upload/gmail/v1/users/me/messages/send") do |env|
        assert_equal "message/rfc822", env.request_headers["Content-Type"]
        assert_equal "media", env.params["uploadType"]
        assert_includes env.body, "Big body text"
        gmail_json_response({ id: "sent-5" })
      end
    end

    big = "x" * (Gmail::SendMessageTool::SIMPLE_UPLOAD_SIZE_LIMIT + 1)
    result = tool.call(to: "friend@example.com", subject: "Big", body: big + "Big body text")
    assert_equal "sent-5", result["id"]
  end

  test "sends attachments to the media upload endpoint when the message is large" do
    tool = expose_gmail_tool("send_message") do |stub|
      stub.post("/upload/gmail/v1/users/me/messages/send") do |env|
        assert_equal "message/rfc822", env.request_headers["Content-Type"]
        assert_includes env.body, Base64.strict_encode64("Binary payload here")
        gmail_json_response({ id: "sent-6" })
      end
    end

    big = "x" * (Gmail::SendMessageTool::SIMPLE_UPLOAD_SIZE_LIMIT + 1)
    result = tool.call(
      to: "friend@example.com",
      subject: "Big",
      body: big,
      attachments: [ { filename: "payload.bin", content: Base64.strict_encode64("Binary payload here") } ]
    )
    assert_equal "sent-6", result["id"]
  end
end
