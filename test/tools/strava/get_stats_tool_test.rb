# frozen_string_literal: true

require "test_helper"

class StravaGetStatsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_stats"
  end

  test "fetches stats for the athlete id from the profile" do
    tool = expose_strava_tool("get_stats") do |stub|
      stub.get("/athlete") { strava_json_response({ id: 123 }) }
      stub.get("/athletes/123/stats") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response({ all_ride_totals: { count: 42, distance: 330_000.0 } })
      end
    end

    result = tool.call
    assert_equal 42, result.dig("all_ride_totals", "count")
  end
end
