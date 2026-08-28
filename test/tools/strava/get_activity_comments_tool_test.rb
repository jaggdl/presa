# frozen_string_literal: true

require "test_helper"

class StravaGetActivityCommentsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity_comments"
  end

  test "fetches an activity's comments with an auth header" do
    tool = expose_strava_tool("get_activity_comments") do |stub|
      stub.get("/api/v3/activities/100/comments") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { "id" => 1, "text" => "Nice ride!" } ])
      end
    end

    result = tool.call(id: 100)
    assert_equal [ { "id" => 1, "text" => "Nice ride!" } ], result
  end

  test "passes page_size and after_cursor as params when provided" do
    tool = expose_strava_tool("get_activity_comments") do |stub|
      stub.get("/api/v3/activities/100/comments") do |env|
        assert_equal "10", env.params["page_size"]
        assert_equal "abc123", env.params["after_cursor"]
        strava_json_response([])
      end
    end

    tool.call(id: 100, page_size: 10, after_cursor: "abc123")
  end
end
