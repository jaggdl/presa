# frozen_string_literal: true

require "test_helper"

class Services::StravaTest < ActiveSupport::TestCase
  test "is an offerable Strava OAuth leaf" do
    assert_equal "strava", Services::Strava.kind
    assert_includes Service.kinds, "strava"
    assert_equal "strava", Services::Strava.oauth_provider.to_s
    assert_equal "https://www.strava.com/oauth/authorize", Services::Strava.oauth_authorize_uri
    assert_equal "https://www.strava.com/oauth/token", Services::Strava.oauth_token_uri
    assert_includes Services::Strava.oauth_scope, "activity:read_all"
  end
end
