# frozen_string_literal: true

require "test_helper"

class StravaGetActivitiesToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activities"
  end

  test "lists activities with default params and an auth header" do
    tool = expose_strava_tool("get_activities") do |stub|
      stub.get("/athlete/activities") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { id: 100, name: "Morning Run", type: "Run" } ])
      end
    end

    result = tool.call
    assert_equal [ { "id" => 100, "name" => "Morning Run", "type" => "Run" } ], result
  end

  test "passes before, after, page, and per_page as params when provided" do
    tool = expose_strava_tool("get_activities") do |stub|
      stub.get("/athlete/activities") do |env|
        assert_equal "1600000000", env.params["after"]
        assert_equal "200", env.params["per_page"]
        assert_equal "2", env.params["page"]
        strava_json_response([])
      end
    end

    tool.call(after: 1_600_000_000, page: 2, per_page: 200)
  end
end
