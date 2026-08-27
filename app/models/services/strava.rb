# frozen_string_literal: true

module Services
  # Strava, backed by Strava's own OAuth2 (per-service BYO client). The user
  # adds a Strava OAuth client credential and authorizes their account; the
  # service then exposes Strava tools (athlete profile, activities) carrying the
  # acquired grant's token. Provider endpoints and scope live here, matching
  # the reference at https://developers.strava.com/docs/reference/.
  class Strava < OauthService
    kind :strava
    icon "strava.png"

    self.oauth_provider = :strava
    self.oauth_authorize_uri = "https://www.strava.com/oauth/authorize"
    self.oauth_token_uri = "https://www.strava.com/oauth/token"
    self.oauth_scope = "activity:read_all,profile:read_all"
  end
end
