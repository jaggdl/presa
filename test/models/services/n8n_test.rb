require "test_helper"

class Services::N8nTest < ActiveSupport::TestCase
  # Ensure Mcp::Error (autoloaded with Mcp::Client) is available.
  Mcp::Client
  test "is a registered preset kind exposing only the base_url and api_key fields" do
    assert_equal "n8n", Services::N8n.kind
    assert_includes Service.kinds, "n8n"
    assert_equal [ "base_url", "api_key" ], Services::N8n.config_fields.keys.map(&:to_s)
  end

  test "reflects the base_url from the config" do
    service = Services::N8n.new(name: "n8n")
    service.config = { base_url: "https://n8n.example.com/mcp", api_key: "key_123" }

    assert_equal "https://n8n.example.com/mcp", service.base_url
  end

  test "builds authorization header from the api_key config" do
    service = Services::N8n.new(name: "n8n")
    service.config = { base_url: "https://n8n.example.com/mcp", api_key: "n8n_123" }

    assert_equal({ "Authorization" => "Bearer n8n_123" }, service.extra_headers)
  end

  test "requires a base_url and an api_key" do
    service = Services::N8n.new(name: "n8n")
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("base_url") }
    assert service.errors[:config].any? { |e| e.to_s.include?("api_key") }
  end

  test "test_connection succeeds when the endpoint answers" do
    service = Services::N8n.new(name: "n8n")
    service.config = { base_url: "https://n8n.example.com/mcp", api_key: "key" }

    fake = Class.new { def list_tools; { "tools" => [] }; end }.new
    service.define_singleton_method(:build_client) { |url:, headers:| fake }

    assert_equal true, service.test_connection(service.config)
  end

  test "test_connection raises when the client errors" do
    service = Services::N8n.new(name: "n8n")
    service.config = { base_url: "https://n8n.example.com/mcp", api_key: "key" }

    failing = Class.new { def list_tools; raise ::Mcp::Error, "401 Unauthorized"; end }.new
    service.define_singleton_method(:build_client) { |url:, headers:| failing }

    assert_raises(::Mcp::Error) { service.test_connection(service.config) }
  end

  test "test_connection raises when a required field is missing" do
    service = Services::N8n.new(name: "n8n")
    service.config = { base_url: "https://n8n.example.com/mcp", api_key: nil }

    error = assert_raises(RuntimeError) { service.test_connection(service.config) }
    assert_match(/Api key is required/, error.message)
  end
end
