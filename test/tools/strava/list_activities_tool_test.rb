# frozen_string_literal: true

require "test_helper"

class StravaListActivitiesToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "list_activities"
  end

  test "hits the athlete activities endpoint with default limit" do
    tool, fake = expose_strava_tool("list_activities")
    tool.call

    assert_includes fake.last_path, "/athlete/activities"
    assert_includes fake.last_path, "per_page=20"
  end

  test "respects limit parameter capped at 200" do
    tool, fake = expose_strava_tool("list_activities")
    tool.call(limit: 5)

    assert_includes fake.last_path, "per_page=5"
  end

  test "caps limit at 200" do
    tool, fake = expose_strava_tool("list_activities")
    tool.call(limit: 999)

    assert_includes fake.last_path, "per_page=200"
  end

  test "includes before and after timestamps when provided" do
    tool, fake = expose_strava_tool("list_activities")
    tool.call(before: 1_700_000_000, after: 1_690_000_000)

    assert_includes fake.last_path, "before=1700000000"
    assert_includes fake.last_path, "after=1690000000"
  end
end