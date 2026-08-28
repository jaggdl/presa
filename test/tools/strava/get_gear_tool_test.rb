# frozen_string_literal: true

require "test_helper"

class StravaGetGearToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_gear"
  end

  test "fetches a piece of gear by id" do
    tool = expose_strava_tool("get_gear") do |stub|
      stub.get("/api/v3/gear/b123456") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        strava_json_response({ "id" => "b123456", "name" => "Cervelo S5" })
      end
    end

    result = tool.call(id: "b123456")
    assert_equal "b123456", result["id"]
    assert_equal "Cervelo S5", result["name"]
  end
end
