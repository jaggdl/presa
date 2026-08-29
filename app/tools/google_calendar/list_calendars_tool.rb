# frozen_string_literal: true

module GoogleCalendar
  # Lists the calendars the authorized account has access to.
  class ListCalendarsTool < Base
    description "List the calendars the connected Google account has access to"

    arguments do
      optional(:limit).filled(:integer, gt?: 0, lteq?: 250).description("Maximum number of calendars to return (default 250)")
    end

    def call(limit: nil)
      params = {}
      params[:maxResults] = limit if limit.present?
      calendar_get("users/me/calendarList", params: params)
    end
  end
end
