# frozen_string_literal: true

require "test_helper"

class GoogleCalendarDeleteEventToolTest < ActiveSupport::TestCase
  include GoogleCalendarToolTestHelper

  test "is exposed for google_calendar services" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    assert_includes kinds, "delete_event"
  end

  test "deletes the event on the primary calendar with an auth header" do
    tool = expose_google_calendar_tool("delete_event") do |stub|
      stub.delete("/calendar/v3/calendars/primary/events/event-1") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        [ 204, {}, "" ]
      end
    end

    result = tool.call(event_id: "event-1")
    assert_equal "", result
  end
end
