require "test_helper"

class OauthGrantTest < ActiveSupport::TestCase
  test "belongs to a service and a client credential" do
    grant = oauth_grants(:gmail_grant)
    assert_equal services(:gmail), grant.service
    assert_equal oauth_client_credentials(:google_credential), grant.oauth_client_credential
  end

  test "is expired when expires_at is in the past" do
    grant = oauth_grants(:gmail_grant)
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
    grant = oauth_grants(:gmail_grant)
    assert grant.refreshable?
    grant.update!(refresh_token: nil)
    assert_not grant.refreshable?
  end
end
