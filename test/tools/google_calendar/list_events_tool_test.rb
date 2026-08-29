# frozen_string_literal: true

require "test_helper"

class GoogleCalendarListEventsToolTest < ActiveSupport::TestCase
  include GoogleCalendarToolTestHelper

  test "is exposed for google_calendar services" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    assert_includes kinds, "list_events"
  end

  test "lists events on the primary calendar with an auth header" do
    tool = expose_google_calendar_tool("list_events") do |stub|
      stub.get("/calendar/v3/calendars/primary/events") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_calendar_json_response({ items: [ { id: "event-1", summary: "Standup" } ] })
      end
    end

    result = tool.call
    assert_equal [ { "id" => "event-1", "summary" => "Standup" } ], result["items"]
  end

  test "passes time bounds, limit, query, and ordering as params" do
    tool = expose_google_calendar_tool("list_events") do |stub|
      stub.get("/calendar/v3/calendars/primary/events") do |env|
        assert_equal "2026-09-01T00:00:00Z", env.params["timeMin"]
        assert_equal "2026-09-30T23:59:59Z", env.params["timeMax"]
        assert_equal "50", env.params["maxResults"].to_s
        assert_equal "standup", env.params["q"]
        assert_equal "false", env.params["singleEvents"].to_s
        assert_equal "updated", env.params["orderBy"]
        google_calendar_json_response({ items: [] })
      end
    end

    tool.call(time_min: "2026-09-01T00:00:00Z", time_max: "2026-09-30T23:59:59Z",
              max_results: 50, q: "standup", single_events: false, order_by: "updated")
  end

  test "lists events on a non-primary calendar" do
    tool = expose_google_calendar_tool("list_events") do |stub|
      stub.get("/calendar/v3/calendars/ownercal%40gmail.com/events") do |env|
        assert_equal "test-access-token", env.request_headers["Authorization"].split.last
        google_calendar_json_response({ items: [ { id: "team-event" } ] })
      end
    end

    result = tool.call(calendar_id: "ownercal@gmail.com")
    assert_equal [ { "id" => "team-event" } ], result["items"]
  end
end
