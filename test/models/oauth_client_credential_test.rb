require "test_helper"

class OauthClientCredentialTest < ActiveSupport::TestCase
  test "is attributed to its team and has many grants" do
    credential = oauth_client_credentials(:google_credential)
    assert_equal teams(:one), credential.team
  end

  test "requires provider, name, client_id, and client_secret" do
    credential = OauthClientCredential.new
    assert_not credential.valid?
    assert credential.errors[:provider].any?
    assert credential.errors[:name].any?
    assert credential.errors[:client_id].any?
    assert credential.errors[:client_secret].any?
  end

  test "client_id is unique within a provider" do
    dup = OauthClientCredential.new(
      provider: "google",
      name: "Prod Google app",
      client_id: "google_client_1",
      client_secret: "x",
      team: teams(:one)
    )
    assert_not dup.valid?
    assert dup.errors[:client_id].any?
  end

  test "masks the secret for display" do
    assert_equal "••••••••", oauth_client_credentials(:google_credential).masked_secret
  end

  test "resolves the provider icon from the provider class" do
    assert_equal "google.png", OauthClientCredential.icon_for("google")
    assert_equal "spotify.png", OauthClientCredential.icon_for("spotify")
    assert_equal "strava.png", OauthClientCredential.icon_for("strava")
    assert_equal "placeholder.png", OauthClientCredential.icon_for("unknown")
  end
end
