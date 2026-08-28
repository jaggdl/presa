# frozen_string_literal: true

require "test_helper"

class StravaGetActivityLapsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity_laps"
  end

  test "fetches a single activity's laps by id" do
    tool = expose_strava_tool("get_activity_laps") do |stub|
      stub.get("/api/v3/activities/100/laps") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { id: 1, lap_index: 1, elapsed_time: 300 } ])
      end
    end

    result = tool.call(id: 100)
    assert_equal [ { "id" => 1, "lap_index" => 1, "elapsed_time" => 300 } ], result
  end
end
