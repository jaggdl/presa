# frozen_string_literal: true

module Oauth
  # Strava OAuth provider endpoints and brand icon, composed by the Strava
  # service and Strava OAuth client credentials.
  class Strava < Base
    key :strava
    icon "strava.png"
    authorize_uri "https://www.strava.com/oauth/authorize"
    token_uri "https://www.strava.com/oauth/token"
  end
end