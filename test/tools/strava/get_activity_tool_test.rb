# frozen_string_literal: true

require "test_helper"

class StravaGetActivityToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_activity"
  end

  test "hits the activity endpoint with a given id" do
    tool, fake = expose_strava_tool("get_activity")
    tool.call(activity_id: 98765)

    assert_includes fake.last_path, "/activities/98765"
  end

  test "includes all efforts when requested" do
    tool, fake = expose_strava_tool("get_activity")
    tool.call(activity_id: 123, include_all_efforts: true)

    assert_includes fake.last_path, "include_all_efforts=true"
  end

  test "does not include all efforts by default" do
    tool, fake = expose_strava_tool("get_activity")
    tool.call(activity_id: 123)

    assert_not_includes fake.last_path, "include_all_efforts"
  end
end