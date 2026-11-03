# frozen_string_literal: true

require "test_helper"

# Covers the OAuth refresh/health behaviour shared by every OAuth-backed
# service (static OAuthService kinds and OpenAPI services). The key guarantee:
# a grant the provider has rejected surfaces an explicit, actionable reconnect
# state and message rather than the provider's raw `invalid_grant`.
class OauthProviderTest < ActiveSupport::TestCase
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
      { "access_token" => "refreshed_token", "expires_in" => 3600 }
    end
  end

  def with_exchange(factory)
    actual = Services::GoogleCalendar.method(:exchange_factory)
    Services::GoogleCalendar.define_singleton_method(:exchange_factory) { factory }
    yield
  ensure
    Services::GoogleCalendar.define_singleton_method(:exchange_factory, &actual)
  end

  test "authorized_token returns the grant's valid token without refreshing" do
    assert_equal "fresh_access", @service.authorized_token
  end

  test "a revoked grant is flagged needs_reconnect and the error is actionable, not raw" do
    @grant.update!(expires_at: 1.minute.ago, refresh_token: "dead")

    error = with_exchange(RejectingExchange) do
      assert_raises(Oauth::ReconnectRequired) { @service.authorized_token }
    end

    assert_includes error.message, "Reconnect Google Calendar"
    assert_not_includes error.message, "invalid_grant"
    assert @grant.reload.needs_reconnect?
    assert_not_nil @grant.needs_reconnect_at
  end

  test "a flagged, expired grant fails fast without another provider round-trip" do
    @grant.update!(expires_at: 1.minute.ago, needs_reconnect: true)

    error = assert_raises(Oauth::ReconnectRequired) { @service.authorized_token }
    assert_includes error.message, "Reconnect Google Calendar"
  end

  test "a still-valid token is returned even while flagged, so cached requests keep working" do
    @grant.update!(needs_reconnect: true)
    assert_equal "fresh_access", @service.authorized_token
  end

  test "refresh_oauth_grant! proactively refreshes a still-valid grant" do
    @grant.update!(expires_at: 10.minutes.from_now)

    with_exchange(RefreshingExchange) { @service.refresh_oauth_grant! }

    assert_equal "refreshed_token", @grant.reload.access_token
  end

  test "storing a fresh grant from a reconnect clears a prior needs_reconnect flag" do
    @grant.update!(needs_reconnect: true)

    grant = @service.store_grant!(
      tokens: { "access_token" => "reconnected", "refresh_token" => "new_ref", "expires_in" => 3600 },
      client_credential: oauth_client_credentials(:google_credential)
    )
    grant.save!

    assert_not grant.reload.needs_reconnect?
    assert_equal "reconnected", grant.access_token
  end

  test "reconnect_message names the service and never exposes secrets" do
    message = @service.reconnect_message
    assert_equal "Reconnect Google Calendar — its authorization has expired or been revoked.", message
  end
end
