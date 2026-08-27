# frozen_string_literal: true

require "test_helper"

class StravaGetAthleteToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_athlete"
  end

  test "returns athlete profile by default" do
    tool, fake = expose_strava_tool("get_athlete")
    result = tool.call

    assert_includes fake.last_path, "/athlete"
    assert_equal 12345678, result["id"]
    assert_equal "Test", result["firstname"]
  end

  test "filters athlete fields when fields param is given" do
    tool, fake = expose_strava_tool("get_athlete")
    result = tool.call(fields: "id,firstname")

    assert_equal 12345678, result["id"]
    assert_equal "Test", result["firstname"]
    assert_nil result["lastname"]
  end
end