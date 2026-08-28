# frozen_string_literal: true

require "test_helper"

class StravaGetActivityZonesToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity_zones"
  end

  test "fetches activity zones by id" do
    tool = expose_strava_tool("get_activity_zones") do |stub|
      stub.get("/api/v3/activities/100/zones") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { "type" => "heartrate", "zones" => [] } ])
      end
    end

    result = tool.call(id: 100)
    assert_equal "heartrate", result.first["type"]
  end
end
