require "test_helper"

class McpClientTest < ActiveSupport::TestCase
  test "parses plain JSON body" do
    client = Mcp::Client.new(url: "http://example.com/mcp")
    result = client.send(:parse_body, '{"result":{"tools":[]}}')
    assert_equal({ "result" => { "tools" => [] } }, result)
  end

  test "parses SSE-framed response" do
    client = Mcp::Client.new(url: "http://example.com/mcp")
    body = "event: message\ndata: {\"result\":{\"tools\":[]}}\n\n"
    result = client.send(:parse_body, body)
    assert_equal({ "result" => { "tools" => [] } }, result)
  end

  test "raises on non-json" do
    client = Mcp::Client.new(url: "http://example.com/mcp")
    assert_raises(JSON::ParserError) { client.send(:parse_body, "event: open nothing") }
  end
end
