# frozen_string_literal: true

require "test_helper"

class StravaGetAthleteZonesToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_athlete_zones"
  end

  test "fetches athlete zones with an auth header" do
    tool = expose_strava_tool("get_athlete_zones") do |stub|
      stub.get("/api/v3/athlete/zones") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response({ heart_rate: { zones: [] } })
      end
    end

    result = tool.call
    assert_equal({ "heart_rate" => { "zones" => [] } }, result)
  end
end
