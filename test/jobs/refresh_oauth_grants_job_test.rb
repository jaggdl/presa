# frozen_string_literal: true

require "test_helper"
require "active_job/test_helper"

class RefreshOauthGrantsJobTest < ActiveJob::TestCase
  setup do
    @service = services(:google_calendar)
    @grant = @service.oauth_grant
  end

  class RejectingExchange
    def refresh(**)
      raise Oauth::ReconnectRequired, "rejected by provider"
    end
  end

  class RefreshingExchange
    def refresh(**)
      { "access_token" => "proactively_refreshed", "expires_in" => 3600 }
    end
  end

  class BoomExchange
    def refresh(**)
      raise "network down"
    end
  end

  def with_exchange(factory)
    actual = Services::GoogleCalendar.method(:exchange_factory)
    Services::GoogleCalendar.define_singleton_method(:exchange_factory) { factory }
    yield
  ensure
    Services::GoogleCalendar.define_singleton_method(:exchange_factory, &actual)
  end

  test "proactively refreshes grants nearing expiry" do
    @grant.update!(expires_at: 5.minutes.from_now)

    with_exchange(RefreshingExchange) { RefreshOauthGrantsJob.perform_now }

    assert_equal "proactively_refreshed", @grant.reload.access_token
    assert_not @grant.needs_reconnect?
  end

  test "flags a grant whose refresh token the provider revoked" do
    @grant.update!(expires_at: 5.minutes.from_now, refresh_token: "dead")

    with_exchange(RejectingExchange) { RefreshOauthGrantsJob.perform_now }

    assert @grant.reload.needs_reconnect?
  end

  test "does not touch grants whose token is not near expiry" do
    @grant.update!(expires_at: 2.hours.from_now)

    with_exchange(RejectingExchange) { RefreshOauthGrantsJob.perform_now }

    assert_equal "fresh_access", @grant.reload.access_token
    assert_not @grant.needs_reconnect?
  end

  test "never raises when a refresh errors unexpectedly" do
    @grant.update!(expires_at: 5.minutes.from_now, refresh_token: "x")

    with_exchange(BoomExchange) do
      assert_nothing_raised { RefreshOauthGrantsJob.perform_now }
    end
  end
end
