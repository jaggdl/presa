# frozen_string_literal: true

require "test_helper"

class StravaGetStarredSegmentsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_starred_segments"
  end

  test "lists starred segments with an auth header" do
    tool = expose_strava_tool("get_starred_segments") do |stub|
      stub.get("/api/v3/segments/starred") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { id: 229781, name: "Hawk Hill" } ])
      end
    end

    result = tool.call
    assert_equal [ { "id" => 229_781, "name" => "Hawk Hill" } ], result
  end

  test "passes page and per_page as params when provided" do
    tool = expose_strava_tool("get_starred_segments") do |stub|
      stub.get("/api/v3/segments/starred") do |env|
        assert_equal "2", env.params["page"]
        assert_equal "50", env.params["per_page"]
        strava_json_response([])
      end
    end

    tool.call(page: 2, per_page: 50)
  end
end
