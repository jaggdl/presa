# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsRunConversionsReportToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "run_conversions_report"
  end

  test "posts a conversions report to the alpha run report endpoint" do
    tool = expose_google_analytics_tool("run_conversions_report") do |stub|
      stub.post("/v1alpha/properties/1234567:runReport") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.request_body)
        assert_equal({ "conversionActions" => [], "attributionModel" => "DATA_DRIVEN" }, body["conversionSpec"])
        assert_equal [ { "name" => "campaignName" } ], body["dimensions"]
        assert_equal [ { "name" => "advertiserAdClicks" } ], body["metrics"]
        google_analytics_json_response({ "rows" => [] })
      end
    end

    result = tool.call(
      property_id: "1234567",
      date_ranges: [ { "start_date" => "30daysAgo", "end_date" => "yesterday" } ],
      dimensions: [ "campaignName" ],
      metrics: [ "advertiserAdClicks" ],
      conversion_spec: { "conversion_actions" => [], "attribution_model" => "DATA_DRIVEN" }
    )
    assert_equal [], result["rows"]
  end
end
