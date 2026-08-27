# frozen_string_literal: true

require "test_helper"

class StravaGetAthleteToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_athlete"
  end

  test "returns the athlete profile with an auth header" do
    tool = expose_strava_tool("get_athlete") do |stub|
      stub.get("/api/v3/athlete") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response({ id: 123, firstname: "Jess", measurement_preference: "feet" })
      end
    end

    result = tool.call
    assert_equal 123, result["id"]
    assert_equal "Jess", result["firstname"]
  end
end
