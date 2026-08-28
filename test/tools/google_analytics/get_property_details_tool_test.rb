# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsGetPropertyDetailsToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "get_property_details"
  end

  test "fetches property details for a bare property id" do
    tool = expose_google_analytics_tool("get_property_details") do |stub|
      stub.get("/v1beta/properties/1234567") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_analytics_json_response({ "name" => "properties/1234567", "displayName" => "My Site" })
      end
    end

    result = tool.call(property_id: "1234567")
    assert_equal "My Site", result["displayName"]
  end

  test "normalizes a properties/ prefixed id to the resource path" do
    hit = false
    tool = expose_google_analytics_tool("get_property_details") do |stub|
      stub.get("/v1beta/properties/9876543") { |env| hit = true; google_analytics_json_response({}) }
    end

    tool.call(property_id: "properties/9876543")
    assert hit, "expected the normalized properties/ path to be requested"
  end
end
