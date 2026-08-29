# frozen_string_literal: true

require "test_helper"

class GoogleCalendarGetEventToolTest < ActiveSupport::TestCase
  include GoogleCalendarToolTestHelper

  test "is exposed for google_calendar services" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    assert_includes kinds, "get_event"
  end

  test "fetches the event on the primary calendar" do
    tool = expose_google_calendar_tool("get_event") do |stub|
      stub.get("/calendar/v3/calendars/primary/events/event-1") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_calendar_json_response({ id: "event-1", summary: "Standup" })
      end
    end

    result = tool.call(event_id: "event-1")
    assert_equal "event-1", result["id"]
  end

  test "fetches the event on a named calendar" do
    tool = expose_google_calendar_tool("get_event") do |stub|
      stub.get("/calendar/v3/calendars/ownercal%40gmail.com/events/event-1") do |env|
        google_calendar_json_response({ id: "event-1", summary: "Team sync" })
      end
    end

    result = tool.call(calendar_id: "ownercal@gmail.com", event_id: "event-1")
    assert_equal "Team sync", result["summary"]
  end
end
