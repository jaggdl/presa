# frozen_string_literal: true

require "test_helper"

class StravaGetSegmentEffortsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_segment_efforts"
  end

  test "lists segment efforts with an auth header" do
    tool = expose_strava_tool("get_segment_efforts") do |stub|
      stub.get("/api/v3/segments/229781/all_efforts") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response([ { id: 123, name: "Morning effort" } ])
      end
    end

    result = tool.call(id: 229_781)
    assert_equal [ { "id" => 123, "name" => "Morning effort" } ], result
  end

  test "passes date range and paging params when provided" do
    tool = expose_strava_tool("get_segment_efforts") do |stub|
      stub.get("/api/v3/segments/229781/all_efforts") do |env|
        assert_equal "2018-01-01T00:00:00Z", env.params["start_date_local"]
        assert_equal "2018-01-02T00:00:00Z", env.params["end_date_local"]
        assert_equal "1", env.params["page"]
        strava_json_response([])
      end
    end

    tool.call(id: 229_781, start_date_local: "2018-01-01T00:00:00Z", end_date_local: "2018-01-02T00:00:00Z", page: 1)
  end
end
