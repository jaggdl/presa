# frozen_string_literal: true

require "test_helper"

class StravaGetActivityToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity"
  end

  test "fetches a single activity by id" do
    tool = expose_strava_tool("get_activity") do |stub|
      stub.get("/activities/100") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response({ id: 100, name: "Evening Ride", distance: 40123.0 })
      end
    end

    result = tool.call(id: 100)
    assert_equal 100, result["id"]
    assert_equal 40_123.0, result["distance"]
  end
end
