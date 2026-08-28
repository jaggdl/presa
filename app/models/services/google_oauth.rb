# frozen_string_literal: true

module Services
  # Abstract base for Google OAuth services (Gmail, Sheets, Drive, Calendar,
  # ...). Holds the endpoints and a sensible default scope shared by every
  # Google-backed service, so concrete subclasses only declare their kind, icon,
  # and service-specific scope. It declares no `kind`, so it is never offerable
  # in the UI.
  class GoogleOauth < OauthService
    self.oauth_provider = :google
    self.oauth_scope = "https://www.googleapis.com/auth/gmail.readonly https://www.google.com/m8/feeds"
  end
end
