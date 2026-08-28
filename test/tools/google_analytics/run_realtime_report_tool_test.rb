# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsRunRealtimeReportToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "run_realtime_report"
  end

  test "posts a realtime report request" do
    tool = expose_google_analytics_tool("run_realtime_report") do |stub|
      stub.post("/v1beta/properties/1234567:runRealtimeReport") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.request_body)
        assert_equal [ { "name" => "unifiedScreenName" } ], body["dimensions"]
        assert_equal [ { "name" => "activeUsers" } ], body["metrics"]
        assert_nil body["dateRanges"]
        google_analytics_json_response({ "rows" => [ { "metricValues" => [ { "value" => "42" } ] } ] })
      end
    end

    result = tool.call(property_id: "1234567", dimensions: [ "unifiedScreenName" ], metrics: [ "activeUsers" ])
    assert_equal "42", result["rows"].first["metricValues"].first["value"]
  end
end
