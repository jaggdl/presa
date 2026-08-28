# frozen_string_literal: true

require "test_helper"

class GoogleAnalyticsRunFunnelReportToolTest < ActiveSupport::TestCase
  include GoogleAnalyticsToolTestHelper

  test "is exposed for google_analytics services" do
    kinds = ApplicationTool.expose_for(services(:google_analytics)).map(&:kind)
    assert_includes kinds, "run_funnel_report"
  end

  test "posts a funnel report with camelized steps and optional args" do
    tool = expose_google_analytics_tool("run_funnel_report") do |stub|
      stub.post("/v1alpha/properties/1234567:runFunnelReport") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.request_body)
        assert_equal [ { "name" => "Page view", "event" => "page_view" } ], body["funnel"]["steps"]
        assert_equal [ { "startDate" => "30daysAgo", "endDate" => "yesterday" } ], body["dateRanges"]
        assert_equal({ "breakdownDimension" => "deviceCategory" }, body["funnelBreakdown"])
        assert_equal({ "nextActionDimension" => "eventName", "limit" => 5 }, body["funnelNextAction"])
        google_analytics_json_response({ "funnelTable" => { "rows" => [] } })
      end
    end

    result = tool.call(
      property_id: "1234567",
      funnel_steps: [ { "name" => "Page view", "event" => "page_view" } ],
      date_ranges: [ { "start_date" => "30daysAgo", "end_date" => "yesterday" } ],
      funnel_breakdown: { "breakdown_dimension" => "deviceCategory" },
      funnel_next_action: { "next_action_dimension" => "eventName", "limit" => 5 }
    )
    assert_not_nil result["funnelTable"]
  end

  test "rejects empty funnel steps with an ArgumentError" do
    tool = expose_google_analytics_tool("run_funnel_report") { |_stub| }

    assert_raises(ArgumentError) do
      tool.call(property_id: "1234567", funnel_steps: [])
    end
  end
end
