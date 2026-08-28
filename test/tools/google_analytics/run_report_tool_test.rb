# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsRunReportToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "run_report"
  end

  test "posts a report request with an auth header and camelCase body" do
    tool = expose_google_analytics_tool("run_report") do |stub|
      stub.post("/v1beta/properties/1234567:runReport") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.request_body)
        assert_equal [ { "name" => "date" } ], body["dimensions"]
        assert_equal [ { "name" => "activeUsers" } ], body["metrics"]
        assert_equal [ { "startDate" => "30daysAgo", "endDate" => "yesterday" } ], body["dateRanges"]
        google_analytics_json_response({ "rows" => [ { "dimensionValues" => [] } ] })
      end
    end

    result = tool.call(
      property_id: "1234567",
      date_ranges: [ { "start_date" => "30daysAgo", "end_date" => "yesterday" } ],
      dimensions: [ "date" ],
      metrics: [ "activeUsers" ]
    )
    assert_equal 1, result["rows"].length
  end

  test "camelizes nested filter and order argument keys" do
    tool = expose_google_analytics_tool("run_report") do |stub|
      stub.post("/v1beta/properties/1234567:runReport") do |env|
        body = JSON.parse(env.request_body)
        assert_equal({ "filter" => { "fieldName" => "eventName", "stringFilter" => { "matchType" => "BEGINS_WITH", "value" => "add" } } }, body["dimensionFilter"])
        assert_equal [ { "metric" => { "metricName" => "eventCount" }, "desc" => true } ], body["orderBys"]
        assert_equal 10, body["limit"]
        assert_equal "USD", body["currencyCode"]
        assert_equal true, body["returnPropertyQuota"]
        google_analytics_json_response({ "rows" => [] })
      end
    end

    tool.call(
      property_id: "1234567",
      date_ranges: [ { "start_date" => "yesterday", "end_date" => "today" } ],
      dimensions: [ "eventName" ],
      metrics: [ "eventCount" ],
      dimension_filter: { "filter" => { "field_name" => "eventName", "string_filter" => { "match_type" => "BEGINS_WITH", "value" => "add" } } },
      order_bys: [ { "metric" => { "metric_name" => "eventCount" }, "desc" => true } ],
      limit: 10,
      currency_code: "USD",
      return_property_quota: true
    )
  end
end
