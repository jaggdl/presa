require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "issue! generates a prefixed token and stores only its digest" do
    user = users(:one)

    raw = ApiToken.issue!(user: user, name: "Cursor")

    assert_match(/\Amcp_[A-Za-z0-9]{32}\z/, raw)
    assert_equal 1, user.api_tokens.count
    refute_equal raw, user.api_tokens.last.token_digest
  end

  test "find_active_by_token returns the token for the raw value" do
    user = users(:one)
    raw = ApiToken.issue!(user: user, name: "Cursor")

    token = ApiToken.find_active_by_token(raw)

    assert_equal user, token.user
  end

  test "find_active_by_token records last_used_at" do
    user = users(:one)
    raw = ApiToken.issue!(user: user)

    travel_to 1.minute.ago do
      ApiToken.find_active_by_token(raw)
    end

    assert_in_delta 1.minute.ago, user.api_tokens.take.last_used_at, 1.second
  end

  test "find_active_by_token returns nil for an unknown token" do
    assert_nil ApiToken.find_active_by_token("mcp_nonexistent")
  end

  test "find_active_by_token returns nil for a revoked token" do
    user = users(:one)
    raw = ApiToken.issue!(user: user)
    ApiToken.find_active_by_token(raw).revoke!

    assert_nil ApiToken.find_active_by_token(raw)
  end

  test "find_active_by_token returns nil for an expired token" do
    user = users(:one)
    raw = ApiToken.issue!(user: user, expires_at: 1.minute.from_now)

    travel_to 2.minutes.from_now do
      assert_nil ApiToken.find_active_by_token(raw)
    end
  end

  test "revoke! revokes the token" do
    user = users(:one)
    raw = ApiToken.issue!(user: user)
    token = ApiToken.find_active_by_token(raw)

    token.revoke!

    assert token.revoked?
    assert_not token.active?
  end
end
