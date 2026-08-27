require "test_helper"

class Services::McpTest < ActiveSupport::TestCase
  test "is a registered service kind" do
    assert_equal "mcp", Services::Mcp.kind
    assert_includes Service.kinds, "mcp"
  end

  test "is categorized as general" do
    assert_equal "general", Services::Mcp.category
    assert Services::Mcp.new(name: "Search").general?
  end

  test "requires url" do
    service = Services::Mcp.new(name: "Search")
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("url") }
  end

  test "parses extra headers" do
    service = Services::Mcp.new(name: "Search")
    service.config = { url: "https://example.com/mcp", headers: '{"Authorization":"Bearer x"}' }

    assert_equal({ "Authorization" => "Bearer x" }, service.extra_headers)
  end

  test "falls back to empty headers for invalid json" do
    service = Services::Mcp.new(name: "Search")
    service.config = { url: "https://example.com/mcp", headers: "not-json" }

    assert_equal({}, service.extra_headers)
  end

  test "validates headers are parseable json" do
    service = Services::Mcp.new(name: "Headers Test", user: users(:one))
    service.config = { url: "https://example.com/mcp", headers: "not-json" }

    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("headers") }
  end

  test "accepts valid json headers" do
    service = Services::Mcp.new(name: "Headers Valid", user: users(:one))
    service.config = { url: "https://example.com/mcp", headers: '{"Authorization":"Bearer x"}' }

    assert service.valid?
  end

  test "discovers remote tools from the client" do
    service = Services::Mcp.new(name: "Search")
    service.config = { url: "https://example.com/mcp", headers: "{}" }

    fake = Object.new
    def fake.list_tools
      { "tools" => [ { "name" => "web_search", "description" => "Search", "inputSchema" => {} } ] }
    end

    service.instance_variable_set(:@client, fake)
    Rails.cache.delete([ "mcp_remote_tools", service.config[:url] ])

    assert_equal [ "web_search" ], service.remote_tools.map { |t| t["name"] }
  end
end
