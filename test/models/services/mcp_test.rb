require "test_helper"
require "set"

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

  test "warm_remote_tools warms each unique endpoint exactly once" do
    one = Services::Mcp.new(name: "One")
    one.config = { url: "https://a.example/mcp", headers: "{}" }
    two = Services::Mcp.new(name: "Two")
    two.config = { url: "https://b.example/mcp", headers: "{}" }
    same_url = Services::Mcp.new(name: "Again")
    same_url.config = { url: "https://b.example/mcp", headers: "{}" }

    calls = []
    lock = Mutex.new
    [ one, two, same_url ].each do |s|
      fake = Object.new
      fake.define_singleton_method(:list_tools) { lock.synchronize { calls << s.name }; { "tools" => [] } }
      s.instance_variable_set(:@client, fake)
    end

    Rails.cache.delete_matched("mcp_remote_tools")
    Services::Mcp.warm_remote_tools([ one, two, same_url ])

    assert_equal Set.new(%w[ One Two ]), calls.to_set
  end
end
