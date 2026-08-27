require "test_helper"

class Services::GmailTest < ActiveSupport::TestCase
  Oauth::Exchange # autoload Oauth::Error
  test "is a registered offerable kind with no config fields" do
    assert_equal "gmail", Services::Gmail.kind
    assert_includes Service.kinds, "gmail"
    assert_empty Services::Gmail.config_fields
  end

  test "inherits provider endpoints from GoogleOauth" do
    assert_equal "google", Services::Gmail.oauth_provider.to_s
    assert_equal "https://accounts.google.com/o/oauth2/v2/auth", Services::Gmail.oauth_authorize_uri
    assert_equal "https://oauth2.googleapis.com/token", Services::Gmail.oauth_token_uri
  end

  test "keeps abstract OAuth bases out of the offerable kinds" do
    assert_not_includes Service.kinds, "google_oauth"
    assert_not_includes Service.kinds, "oauth_service"
  end

  test "is valid as an OAuth service" do
    assert services(:gmail).valid?
  end

  test "reports connected only once it has a grant" do
    assert services(:gmail).connected?
  end

  test "exposes the provider name" do
    assert_equal "google", services(:gmail).provider
  end

  test "builds an authorize url with the client and redirect target" do
    service = services(:gmail)
    assert service.oauth_client_credential.present?

    url = service.authorize_url(redirect_uri: "https://presa.example/oauth/callback", state: "abc123")
    assert_includes url, "https://accounts.google.com/o/oauth2/v2/auth"
    assert_includes url, "client_id=google_client_1"
    assert_includes url, "redirect_uri=https%3A%2F%2Fpresa.example%2Foauth%2Fcallback"
    assert_includes url, "state=abc123"
  end

  test "authorized_token returns the valid access token without refreshing" do
    grant = oauth_grants(:gmail_grant)
    grant.update!(expires_at: 2.hours.from_now)

    service = services(:gmail)
    assert_equal "fresh_access", service.authorized_token
  end

  test "authorized_token refreshes when the token is expired" do
    grant = oauth_grants(:gmail_grant)
    grant.update!(expires_at: 1.minute.ago)
    service = services(:gmail)

    fake = Oauth::Exchange.new
    fake.define_singleton_method(:refresh) do |token_uri:, refresh_token:, client_id:, client_secret:|
      { "access_token" => "rotated_access", "expires_in" => 3600 }
    end
    service.instance_variable_set(:@exchange, fake)

    assert_equal "rotated_access", service.authorized_token
    assert_equal "rotated_access", grant.reload.access_token
  end

  test "authorized_token raises when there is no grant" do
    service = Services::Gmail.create!(name: "Gmail2", user: users(:one), type: "Services::Gmail")
    assert_raises(Oauth::Error) { service.authorized_token }
  end

  test "authorized_token raises when refresh cannot complete" do
    grant = oauth_grants(:gmail_grant)
    grant.update!(expires_at: 1.minute.ago, refresh_token: nil)
    service = services(:gmail)

    assert_raises(Oauth::Error) { service.authorized_token }
  end
end
