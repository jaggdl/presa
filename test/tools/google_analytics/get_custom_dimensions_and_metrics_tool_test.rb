# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsGetCustomDimensionsAndMetricsToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "get_custom_dimensions_and_metrics"
  end

  test "filters the metadata to custom dimensions and metrics only" do
    tool = expose_google_analytics_tool("get_custom_dimensions_and_metrics") do |stub|
      stub.get("/v1beta/properties/1234567/metadata") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_analytics_json_response({
          "dimensions" => [
            { "apiName" => "date", "customDefinition" => false },
            { "apiName" => "customUser:badge", "customDefinition" => true }
          ],
          "metrics" => [
            { "apiName" => "activeUsers", "customDefinition" => false },
            { "apiName" => "custom:revenue", "customDefinition" => true }
          ]
        })
      end
    end

    result = tool.call(property_id: "1234567")
    assert_equal [ "customUser:badge" ], result["custom_dimensions"].map { |d| d["apiName"] }
    assert_equal [ "custom:revenue" ], result["custom_metrics"].map { |m| m["apiName"] }
  end
end
