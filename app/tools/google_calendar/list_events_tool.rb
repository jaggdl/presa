# frozen_string_literal: true

module GoogleCalendar
  # Lists events on a calendar, optionally bounded by time and a free-text
  # query.
  class ListEventsTool < Base
    description "List events on a Google Calendar, optionally bounded by time and a free-text query"

    arguments do
      optional(:calendar_id).filled(:string).description("Calendar to list events from, e.g. an email address or 'primary' (default 'primary')")
      optional(:time_min).filled(:string).description("Lower bound (inclusive) for event start time as RFC3339, e.g. '2026-09-01T00:00:00Z'")
      optional(:time_max).filled(:string).description("Upper bound (exclusive) for event start time as RFC3339, e.g. '2026-09-30T23:59:59Z'")
      optional(:max_results).filled(:integer, gt?: 0, lteq?: 2500).description("Maximum number of events to return (default 250)")
      optional(:q).filled(:string).description("Free-text search terms matching the event summary, description, or location")
      optional(:single_events).filled(:bool).description("Expand recurring events into individual instances (default true)")
      optional(:order_by).filled(:string).description("Order results by 'startTime' (default) or 'updated'")
    end

    def call(calendar_id: "primary", time_min: nil, time_max: nil, max_results: nil,
             q: nil, single_events: nil, order_by: nil)
      params = {
        timeMin: time_min,
        timeMax: time_max,
        maxResults: max_results,
        q: q,
        singleEvents: single_events,
        orderBy: order_by
      }.compact

      calendar_get(calendar_path(calendar_id, "events"), params: params)
    end
  end
end
