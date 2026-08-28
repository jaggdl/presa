require "test_helper"

class Services::McpDiscoveryErrorTest < ActiveSupport::TestCase
  test "remote_tools returns empty and records the error on discovery failure" do
    service = Services::Mcp.new(name: "Search", team: teams(:one))
    service.config = { url: "https://example.com/mcp", headers: "{}" }

    # Force the autoloaded Mcp::Client (and its Mcp::Error) to load.
    Mcp::Client

    failing = Object.new
    def failing.list_tools
      raise ::Mcp::Error, "MCP request failed (401): Unauthorized"
    end
    service.instance_variable_set(:@client, failing)

    assert_equal [], service.remote_tools
    assert_match(/401/, service.remote_tools_error.message)
  end
end
