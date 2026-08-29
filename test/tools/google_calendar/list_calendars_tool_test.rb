# frozen_string_literal: true

require "test_helper"

class GoogleCalendarListCalendarsToolTest < ActiveSupport::TestCase
  include GoogleCalendarToolTestHelper

  test "is exposed for google_calendar services" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    assert_includes kinds, "list_calendars"
  end

  test "lists calendars with an auth header" do
    tool = expose_google_calendar_tool("list_calendars") do |stub|
      stub.get("/calendar/v3/users/me/calendarList") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        google_calendar_json_response({ items: [ { id: "primary", summary: "My Calendar" } ] })
      end
    end

    result = tool.call(limit: nil)
    assert_equal [ { "id" => "primary", "summary" => "My Calendar" } ], result["items"]
  end

  test "passes the maxResults limit as a param" do
    tool = expose_google_calendar_tool("list_calendars") do |stub|
      stub.get("/calendar/v3/users/me/calendarList") do |env|
        assert_equal "50", env.params["maxResults"].to_s
        google_calendar_json_response({ items: [] })
      end
    end

    tool.call(limit: 50)
  end
end
