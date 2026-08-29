# frozen_string_literal: true

require "test_helper"

class Services::StravaTest < ActiveSupport::TestCase
  test "is an offerable Strava OAuth leaf" do
    assert_equal "strava", Services::Strava.kind
    assert_includes Service.kinds, "strava"
    assert_equal "strava", Services::Strava.oauth_provider.to_s
    assert_equal "https://www.strava.com/oauth/authorize", Services::Strava.provider_class.authorize_uri
    assert_equal "https://www.strava.com/oauth/token", Services::Strava.provider_class.token_uri
    assert_equal Oauth::Strava, Services::Strava.provider_class
    assert_includes Services::Strava.oauth_scope, "activity:read_all"
  end

  test "is categorized as fitness" do
    assert_equal "fitness", Services::Strava.category
  end

  test "composes a client against the API base URL" do
    service = services(:strava)
    assert_instance_of Oauth::Client, service.client
  end

  test "exposes the strava toolset" do
    kinds = ApplicationTool.expose_for(services(:strava)).map(&:kind)
    expected = %w[
      get_athlete get_stats get_activities get_activity get_athlete_zones get_athlete_clubs
      get_athlete_routes get_starred_segments get_gear get_activity_zones get_activity_laps
      get_activity_kudos get_activity_comments get_activity_streams get_segment get_segment_efforts
    ]
    expected.each { |kind| assert_includes kinds, kind }
  end
end
