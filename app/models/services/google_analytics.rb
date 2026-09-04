# frozen_string_literal: true

module Services
  # Google Analytics, backed by Google OAuth2 (per-service BYO client), the
  # same provider flow as Google Calendar. The user adds a Google OAuth client credential
  # and authorizes their account with the analytics.readonly scope; the service
  # then exposes GA4 tools (account/property lookup and Data API reports)
  # carrying the acquired grant's token.
  class GoogleAnalytics < ::OauthService
    kind :google_analytics
    icon "google_analytics.png"
    category :productivity

    self.oauth_provider = :google
    self.oauth_scope = "https://www.googleapis.com/auth/analytics.readonly"
  end
end
