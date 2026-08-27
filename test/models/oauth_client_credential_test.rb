require "test_helper"

class OauthClientCredentialTest < ActiveSupport::TestCase
  test "is attributed to its creator and has many grants" do
    credential = oauth_client_credentials(:google_credential)
    assert_equal users(:one), credential.created_by
  end

  test "requires provider, client_id, and client_secret" do
    credential = OauthClientCredential.new
    assert_not credential.valid?
    assert credential.errors[:provider].any?
    assert credential.errors[:client_id].any?
    assert credential.errors[:client_secret].any?
  end

  test "client_id is unique within a provider" do
    dup = OauthClientCredential.new(
      provider: "google",
      client_id: "google_client_1",
      client_secret: "x",
      created_by: users(:one)
    )
    assert_not dup.valid?
    assert dup.errors[:client_id].any?
  end

  test "masks the secret for display" do
    assert_equal "••••••••", oauth_client_credentials(:google_credential).masked_secret
  end
end
