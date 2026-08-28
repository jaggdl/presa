# frozen_string_literal: true

require "test_helper"

class StravaGetAthleteClubsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_athlete_clubs"
  end

  test "lists clubs with an auth header" do
    tool = expose_strava_tool("get_athlete_clubs") do |stub|
      stub.get("/api/v3/athlete/clubs") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { id: 1, name: "Sunday Riders" } ])
      end
    end

    result = tool.call
    assert_equal [ { "id" => 1, "name" => "Sunday Riders" } ], result
  end

  test "passes page and per_page as params when provided" do
    tool = expose_strava_tool("get_athlete_clubs") do |stub|
      stub.get("/api/v3/athlete/clubs") do |env|
        assert_equal "2", env.params["page"]
        assert_equal "50", env.params["per_page"]
        strava_json_response([])
      end
    end

    tool.call(page: 2, per_page: 50)
  end
end
