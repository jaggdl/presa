# frozen_string_literal: true

require "test_helper"

class StravaGetActivityKudosToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity_kudos"
  end

  test "fetches an activity's kudos by id" do
    tool = expose_strava_tool("get_activity_kudos") do |stub|
      stub.get("/api/v3/activities/100/kudos") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { firstname: "Erin", lastname: "Baker" } ])
      end
    end

    result = tool.call(id: 100)
    assert_equal [ { "firstname" => "Erin", "lastname" => "Baker" } ], result
  end

  test "passes page and per_page as params when provided" do
    tool = expose_strava_tool("get_activity_kudos") do |stub|
      stub.get("/api/v3/activities/100/kudos") do |env|
        assert_equal "2", env.params["page"]
        assert_equal "50", env.params["per_page"]
        strava_json_response([])
      end
    end

    tool.call(id: 100, page: 2, per_page: 50)
  end
end
