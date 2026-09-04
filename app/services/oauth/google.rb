# frozen_string_literal: true

module Oauth
  # Google OAuth provider endpoints and brand icon, composed by Googles-backed
  # services (Calendar, Sheets, ...) and Google OAuth client credentials.
  class Google < Base
    key :google
    icon "google.png"
    authorize_uri "https://accounts.google.com/o/oauth2/v2/auth"
    token_uri "https://oauth2.googleapis.com/token"
  end
end
