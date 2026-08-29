# frozen_string_literal: true

require "test_helper"

class Services::GoogleCalendarTest < ActiveSupport::TestCase
  test "is an offerable GoogleCalendar OAuth leaf" do
    assert_equal "calendar", Services::GoogleCalendar.kind
    assert_includes Service.kinds, "calendar"
    assert_equal "google", Services::GoogleCalendar.oauth_provider.to_s
    assert_equal Oauth::Google, Services::GoogleCalendar.provider_class
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", Services::GoogleCalendar.new.authorize_uri
    assert_equal "https://oauth2.googleapis.com/token", Services::GoogleCalendar.new.token_uri
    assert_equal "https://www.googleapis.com/auth/calendar", Services::GoogleCalendar.oauth_scope
    assert_equal "https://www.googleapis.com/calendar/v3", Services::GoogleCalendar.oauth_api_base_url
    assert_empty Services::GoogleCalendar.config_fields
  end

  test "composes a client against the API base URL" do
    service = services(:google_calendar)
    client = service.client

    assert_instance_of Oauth::Client, client
  end

  test "memoizes one client per API base URL" do
    service = services(:google_calendar)
    assert_same service.client, service.client
    assert_not_same service.client, service.client(base_url: "https://other.example.com")
  end

  test "raises when no API base URL is configured" do
    service = services(:google_calendar)
    assert_raises(ArgumentError) { service.client(base_url: "") }
  end

  test "has a friendly display name and calendar icon" do
    assert_equal "Google Calendar", Services::GoogleCalendar.display_name
    assert_equal "google_calendar.png", Services::GoogleCalendar.new.icon
  end

  test "is categorized as productivity" do
    assert_equal "productivity", Services::GoogleCalendar.category
    assert Services::GoogleCalendar.new(name: "Calendar").productivity?
  end

  test "is valid as an OAuth service and reports connected with a grant" do
    assert services(:google_calendar).valid?
    assert services(:google_calendar).connected?
  end

  test "exposes the provider name" do
    assert_equal "google", services(:google_calendar).provider
  end

  test "authorized_token returns the valid access token from its grant" do
    assert_equal "fresh_access", services(:google_calendar).authorized_token
  end

  test "exposes the calendar toolset" do
    kinds = ApplicationTool.expose_for(services(:google_calendar)).map(&:kind)
    expected = %w[
      list_calendars list_events get_event create_event update_event delete_event
    ]
    expected.each { |kind| assert_includes kinds, kind }
  end
end
