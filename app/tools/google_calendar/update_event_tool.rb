# frozen_string_literal: true

module GoogleCalendar
  # Updates selected fields of an existing event. Only the provided fields are
  # changed; omitted fields are left untouched.
  class UpdateEventTool < Base
    description "Update an existing Google Calendar event. Only the fields you provide are changed"

    arguments do
      optional(:calendar_id).filled(:string).description("Calendar the event belongs to (default 'primary')")
      required(:event_id).filled(:string).description("Id of the event to update")
      optional(:summary).filled(:string).description("New title of the event")
      optional(:start_time).filled(:string).description("New start as RFC3339, or a bare YYYY-MM-DD for an all-day event")
      optional(:end_time).filled(:string).description("New end as RFC3339, or a bare YYYY-MM-DD for an all-day event")
      optional(:time_zone).filled(:string).description("IANA time zone applied to updated start/end times without an offset")
      optional(:description).filled(:string).description("New event description")
      optional(:location).filled(:string).description("New event location")
      optional(:attendees).array(:string).description("New email addresses to invite (replaces existing attendees)")
    end

    def call(calendar_id: "primary", event_id:, summary: nil, start_time: nil, end_time: nil,
             time_zone: nil, description: nil, location: nil, attendees: nil)
      body = {}
      body[:summary] = summary if summary.present?
      body[:start] = date_field(start_time, time_zone) if start_time.present?
      body[:end] = date_field(end_time, time_zone) if end_time.present?
      body[:description] = description if description.present?
      body[:location] = location if location.present?
      body[:attendees] = normalize_attendees(attendees) if attendees.present?

      calendar_patch(calendar_path(calendar_id, "events", event_id), body: body)
    end
  end
end
