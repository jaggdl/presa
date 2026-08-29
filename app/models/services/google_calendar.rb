# frozen_string_literal: true

module Services
  # Google Calendar, backed by Google OAuth2 (per-service BYO client). The
  # user adds a Google OAuth client credential and authorizes their account
  # with the calendar scope; the service then exposes Google Calendar tools
  # (list/get/create/update/delete events, list calendars) carrying the
  # acquired grant's token.
  class GoogleCalendar < ::OauthService
    kind :calendar
    display_name "Google Calendar"
    icon "google_calendar.png"
    category :productivity

    self.oauth_provider = :google
    self.oauth_scope = "https://www.googleapis.com/auth/calendar"
    self.oauth_api_base_url = "https://www.googleapis.com/calendar/v3"
  end
end
