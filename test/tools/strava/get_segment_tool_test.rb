# frozen_string_literal: true

require "test_helper"

class StravaGetSegmentToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_segment"
  end

  test "fetches a segment by id with an auth header" do
    tool = expose_strava_tool("get_segment") do |stub|
      stub.get("/api/v3/segments/229781") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response({ id: 229781, name: "Hawk Hill", climb_category: 1 })
      end
    end

    result = tool.call(id: 229_781)
    assert_equal 229_781, result["id"]
    assert_equal "Hawk Hill", result["name"]
  end
end
