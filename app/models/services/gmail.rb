# frozen_string_literal: true

module Services
  # Gmail, backed by Google OAuth2 (per-service BYO client). The user adds a
  # Google OAuth client credential and authorizes their account; the service
  # then exposes Gmail tools (send/read) carrying the acquired grant's token.
  # Google endpoints and icon come from the Oauth::Google provider class.
  class Gmail < OauthService
    kind :gmail
    icon "gmail.png"
    category :productivity

    self.oauth_provider = :google
    self.oauth_scope = "https://www.googleapis.com/auth/gmail.send https://www.googleapis.com/auth/gmail.readonly"
  end
end
