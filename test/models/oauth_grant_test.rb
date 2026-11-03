require "test_helper"

class OauthGrantTest < ActiveSupport::TestCase
  test "belongs to a service and a client credential" do
    grant = oauth_grants(:google_calendar_grant)
    assert_equal services(:google_calendar), grant.service
    assert_equal oauth_client_credentials(:google_credential), grant.oauth_client_credential
  end

  test "is expired when expires_at is in the past" do
    grant = oauth_grants(:google_calendar_grant)
    assert_not grant.expired?
    grant.update!(expires_at: 1.minute.ago)
    assert grant.expired?
  end

  test "is not expired when expires_at is nil (non-rotating tokens like Notion)" do
    grant = oauth_grants(:notion_grant)
    assert_nil grant.expires_at
    assert_not grant.expired?
    assert_not grant.refreshable?
  end

  test "is refreshable when a refresh token is present" do
    grant = oauth_grants(:google_calendar_grant)
    assert grant.refreshable?
    grant.update!(refresh_token: nil)
    assert_not grant.refreshable?
  end

  test "starts out not needing a reconnect" do
    assert_not oauth_grants(:google_calendar_grant).needs_reconnect?
  end

  test "mark_needs_reconnect! records the state and timestamp, idempotently" do
    grant = oauth_grants(:google_calendar_grant)

    assert_not grant.needs_reconnect?
    grant.mark_needs_reconnect!
    assert grant.reload.needs_reconnect?
    assert_not_nil grant.needs_reconnect_at

    first_marked_at = grant.needs_reconnect_at
    grant.mark_needs_reconnect!
    assert_equal first_marked_at, grant.reload.needs_reconnect_at
  end

  test "clear_needs_reconnect! resets the state" do
    grant = oauth_grants(:google_calendar_grant)
    grant.mark_needs_reconnect!
    grant.clear_needs_reconnect!
    assert_not grant.reload.needs_reconnect?
    assert_nil grant.needs_reconnect_at
  end
end
