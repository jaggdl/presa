# frozen_string_literal: true

module GoogleCalendar
  # Deletes an event from a calendar.
  class DeleteEventTool < Base
    description "Delete an event from a Google Calendar"

    arguments do
      optional(:calendar_id).filled(:string).description("Calendar the event belongs to (default 'primary')")
      required(:event_id).filled(:string).description("Id of the event to delete")
    end

    def call(calendar_id: "primary", event_id:)
      calendar_delete(calendar_path(calendar_id, "events", event_id))
    end
  end
end
