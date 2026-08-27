require "test_helper"

class Services::HomeAssistantTest < ActiveSupport::TestCase
  # Ensure Mcp::Error (autoloaded with Mcp::Client) is available.
  Mcp::Client
  test "is a registered preset kind exposing only the base_url and access_token fields" do
    assert_equal "home_assistant", Services::HomeAssistant.kind
    assert_includes Service.kinds, "home_assistant"
    assert_equal [ "base_url", "access_token" ], Services::HomeAssistant.config_fields.keys.map(&:to_s)
  end

  test "resolves the mcp endpoint from the base_url" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    service.config = { base_url: "http://homeassistant.local:8123", access_token: "ha_123" }

    assert_equal "http://homeassistant.local:8123/api/mcp", service.base_url
  end

  test "resolves the mcp endpoint without a trailing slash when base_url has one" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    service.config = { base_url: "http://homeassistant.local:8123/", access_token: "ha_123" }

    assert_equal "http://homeassistant.local:8123/api/mcp", service.base_url
  end

  test "builds authorization header from the access_token config" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    service.config = { base_url: "http://homeassistant.local:8123", access_token: "ha_123" }

    assert_equal({ "Authorization" => "Bearer ha_123" }, service.extra_headers)
  end

  test "requires a base_url and an access_token" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("base_url") }
    assert service.errors[:config].any? { |e| e.to_s.include?("access_token") }
  end

  test "test_connection succeeds when the endpoint answers" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    service.config = { base_url: "http://homeassistant.local:8123", access_token: "key" }

    fake = Class.new { def list_tools; { "tools" => [] }; end }.new
    service.define_singleton_method(:build_client) { |url:, headers:| fake }

    assert_equal true, service.test_connection(service.config)
  end

  test "test_connection raises when the client errors" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    service.config = { base_url: "http://homeassistant.local:8123", access_token: "key" }

    failing = Class.new { def list_tools; raise ::Mcp::Error, "401 Unauthorized"; end }.new
    service.define_singleton_method(:build_client) { |url:, headers:| failing }

    assert_raises(::Mcp::Error) { service.test_connection(service.config) }
  end

  test "test_connection raises when a required field is missing" do
    service = Services::HomeAssistant.new(name: "Home Assistant")
    service.config = { base_url: "http://homeassistant.local:8123", access_token: nil }

    error = assert_raises(RuntimeError) { service.test_connection(service.config) }
    assert_match(/Access token is required/, error.message)
  end
end
