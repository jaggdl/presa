# frozen_string_literal: true

require "test_helper"

class GoogleCalendarUpdateEventToolTest < ActiveSupport::TestCase
  include GoogleCalendarToolTestHelper

  test "is exposed for google_calendar services" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    assert_includes kinds, "update_event"
  end

  test "patches only the provided fields with an auth header" do
    tool = expose_google_calendar_tool("update_event") do |stub|
      stub.patch("/calendar/v3/calendars/primary/events/event-1") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.body)
        assert_equal "Retitled meeting", body["summary"]
        assert_nil body["start"]
        assert_nil body["location"]
        google_calendar_json_response({ id: "event-1", summary: "Retitled meeting" })
      end
    end

    result = tool.call(event_id: "event-1", summary: "Retitled meeting")
    assert_equal "Retitled meeting", result["summary"]
  end

  test "updates start and end times with a time zone" do
    tool = expose_google_calendar_tool("update_event") do |stub|
      stub.patch("/calendar/v3/calendars/primary/events/event-1") do |env|
        body = JSON.parse(env.body)
        assert_equal "2026-09-02T14:00:00", body.dig("start", "dateTime")
        assert_equal "2026-09-02T15:00:00", body.dig("end", "dateTime")
        assert_equal "Europe/London", body.dig("start", "timeZone")
        google_calendar_json_response({ id: "event-1" })
      end
    end

    tool.call(event_id: "event-1", start_time: "2026-09-02T14:00:00",
              end_time: "2026-09-02T15:00:00", time_zone: "Europe/London")
  end

  test "updates a named calendar's event" do
    tool = expose_google_calendar_tool("update_event") do |stub|
      stub.patch("/calendar/v3/calendars/ownercal%40gmail.com/events/event-1") do |env|
        google_calendar_json_response({ id: "event-1", description: "Updated" })
      end
    end

    result = tool.call(calendar_id: "ownercal@gmail.com", event_id: "event-1", description: "Updated")
    assert_equal "Updated", result["description"]
  end
end
