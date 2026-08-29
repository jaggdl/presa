# frozen_string_literal: true

require "test_helper"

class GoogleCalendarCreateEventToolTest < ActiveSupport::TestCase
  include GoogleCalendarToolTestHelper

  test "is exposed for google_calendar services" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    assert_includes kinds, "create_event"
  end

  test "creates a timed event with an auth header" do
    tool = expose_google_calendar_tool("create_event") do |stub|
      stub.post("/calendar/v3/calendars/primary/events") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        body = JSON.parse(env.body)
        assert_equal "Project kickoff", body["summary"]
        assert_equal "2026-09-01T10:00:00-04:00", body.dig("start", "dateTime")
        assert_equal "2026-09-01T11:00:00-04:00", body.dig("end", "dateTime")
        google_calendar_json_response({ id: "new-event", summary: "Project kickoff" })
      end
    end

    result = tool.call(summary: "Project kickoff",
                       start_time: "2026-09-01T10:00:00-04:00",
                       end_time: "2026-09-01T11:00:00-04:00")
    assert_equal "new-event", result["id"]
  end

  test "creates an all-day event with a time zone and attendees" do
    tool = expose_google_calendar_tool("create_event") do |stub|
      stub.post("/calendar/v3/calendars/primary/events") do |env|
        body = JSON.parse(env.body)
        assert_equal "2026-09-01", body.dig("start", "date")
        assert_equal "2026-09-02", body.dig("end", "date")
        assert_equal "America/New_York", body.dig("start", "timeZone")
        assert_equal({ "email" => "alice@example.com" }, body["attendees"].first)
        assert_equal "Wonderland, Room 1", body["location"]
        google_calendar_json_response({ id: "all-day", summary: "Offsite" })
      end
    end

    tool.call(summary: "Offsite", start_time: "2026-09-01", end_time: "2026-09-02",
              time_zone: "America/New_York", location: "Wonderland, Room 1",
              attendees: [ "alice@example.com" ])
  end

  test "creates the event on a named calendar" do
    tool = expose_google_calendar_tool("create_event") do |stub|
      stub.post("/calendar/v3/calendars/ownercal%40gmail.com/events") do |env|
        google_calendar_json_response({ id: "new-event", summary: "Sync" })
      end
    end

    result = tool.call(calendar_id: "ownercal@gmail.com", summary: "Sync",
                       start_time: "2026-09-01T09:00:00Z", end_time: "2026-09-01T09:30:00Z")
    assert_equal "new-event", result["id"]
  end

  test "includes description when given" do
    tool = expose_google_calendar_tool("create_event") do |stub|
      stub.post("/calendar/v3/calendars/primary/events") do |env|
        body = JSON.parse(env.body)
        assert_equal "Bring slides", body["description"]
        google_calendar_json_response({ id: "desc" })
      end
    end

    tool.call(summary: "Review", start_time: "2026-09-01T09:00:00Z",
              end_time: "2026-09-01T09:30:00Z", description: "Bring slides")
  end
end
