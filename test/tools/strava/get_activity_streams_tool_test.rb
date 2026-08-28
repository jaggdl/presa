# frozen_string_literal: true

require "test_helper"

class StravaGetActivityStreamsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity_streams"
  end

  test "fetches activity streams with an auth header" do
    tool = expose_strava_tool("get_activity_streams") do |stub|
      stub.get("/api/v3/activities/100/streams") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { "type" => "distance", "data" => [] } ])
      end
    end

    result = tool.call(id: 100)
    assert_equal "distance", result.first["type"]
  end

  test "passes keys and keys_by_type as params when provided" do
    tool = expose_strava_tool("get_activity_streams") do |stub|
      stub.get("/api/v3/activities/100/streams") do |env|
        assert_equal "distance,time", env.params["keys"]
        assert_equal "true", env.params["keys_by_type"]
        strava_json_response([])
      end
    end

    tool.call(id: 100, keys: "distance,time", keys_by_type: true)
  end
end
