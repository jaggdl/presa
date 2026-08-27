# frozen_string_literal: true

module Services
  # Gmail, backed by Google OAuth2 (per-service BYO client). The user adds a
  # Google OAuth client credential and authorizes their account; the service
  # then exposes Gmail tools (send/read) carrying the acquired grant's token.
  # Provider endpoints come from the shared Services::GoogleOauth base.
  class Gmail < GoogleOauth
    kind :gmail
    icon "gmail.png"

    self.oauth_scope = "https://www.googleapis.com/auth/gmail.send https://www.googleapis.com/auth/gmail.readonly"
  end
end
