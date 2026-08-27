# frozen_string_literal: true

require "test_helper"

class StravaGetAthleteStatsToolTest < ActiveSupport::TestCase
  include StravaToolTestHelper

  test "is exposed for strava services" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    assert_includes kinds, "get_athlete_stats"
  end

  test "resolves athlete id from profile when not provided" do
    tool, fake = expose_strava_tool("get_athlete_stats")
    tool.call

    # First call resolves athlete (/athlete), second fetches stats
    assert_includes fake.paths.first, "/athlete"
    assert_includes fake.paths.last, "/athletes/12345678/stats"
  end

  test "uses explicit athlete id when provided" do
    tool, fake = expose_strava_tool("get_athlete_stats")
    tool.call(athlete_id: 42)

    assert_includes fake.last_path, "/athletes/42/stats"
  end
end