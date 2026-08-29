# frozen_string_literal: true

module GoogleCalendar
  # Fetches a single event's details by its id.
  class GetEventTool < Base
    description "Get the details of a single Google Calendar event by its id"

    arguments do
      optional(:calendar_id).filled(:string).description("Calendar the event belongs to (default 'primary')")
      required(:event_id).filled(:string).description("Id of the event to fetch")
    end

    def call(calendar_id: "primary", event_id:)
      calendar_get(calendar_path(calendar_id, "events", event_id))
    end
  end
end
