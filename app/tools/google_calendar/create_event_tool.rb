# frozen_string_literal: true

module GoogleCalendar
  # Creates a new event on a calendar.
  class CreateEventTool < Base
    description "Create a new event on a Google Calendar"

    arguments do
      optional(:calendar_id).filled(:string).description("Calendar to add the event to (default 'primary')")
      required(:summary).filled(:string).description("Title of the event")
      required(:start_time).filled(:string).description("Start of the event as RFC3339, e.g. '2026-09-01T10:00:00-04:00', or a bare YYYY-MM-DD for an all-day event")
      required(:end_time).filled(:string).description("End of the event as RFC3339 (must be after start_time), or a bare YYYY-MM-DD for an all-day event")
      optional(:description).filled(:string).description("Event description")
      optional(:location).filled(:string).description("Event location")
      optional(:time_zone).filled(:string).description("IANA time zone, e.g. 'America/New_York', applied to bare dates or datetimes without an offset")
      optional(:attendees).array(:string).description("Email addresses of attendees to invite")
    end

    def call(calendar_id: "primary", summary:, start_time:, end_time:, description: nil,
             location: nil, time_zone: nil, attendees: nil)
      body = {
        summary: summary,
        start: date_field(start_time, time_zone),
        end: date_field(end_time, time_zone)
      }
      body[:description] = description if description.present?
      body[:location] = location if location.present?
      body[:attendees] = normalize_attendees(attendees) if attendees.present?

      calendar_post(calendar_path(calendar_id, "events"), body: body)
    end
  end
end
