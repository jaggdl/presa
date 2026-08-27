require "test_helper"

class BotAuthorizationTest < ActiveSupport::TestCase
  setup do
    @workspace = workspaces(:one)
  end

  test "initiate! creates a pending authorization" do
    bot = BotAuthorization.initiate!(workspace: @workspace, name: "coder", justification: "invoices")

    assert bot.pending?
    assert_equal "coder", bot.name
    assert_equal "invoices", bot.justification
    assert_equal bot.workspace, @workspace
  end

  test "initiate! assigns a unique request token" do
    a = BotAuthorization.initiate!(workspace: @workspace, name: "a")
    b = BotAuthorization.initiate!(workspace: @workspace, name: "b")

    assert a.request_token.present?
    refute_equal a.request_token, b.request_token
  end

  test "approve! returns a 10-digit code and marks approved" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "x")
    code = authorization.approve!

    assert_match(/\A\d{10}\z/, code)
    assert_equal 10, code.length
    assert authorization.approved?
    assert authorization.code_digest.present?
    assert authorization.code_expires_at > Time.current
    refute_nil authorization.approved_at
  end

  test "redeem! issues a token for a valid code and consumes the request" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "x")
    code = authorization.approve!

    raw = authorization.redeem!(code)

    assert_match(/\Amcp_/, raw)
    assert authorization.consumed?
    assert_nil authorization.code_digest
  end

  test "redeem! is single-use" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "x")
    code = authorization.approve!
    authorization.redeem!(code)

    assert_nil authorization.redeem!(code)
  end

  test "redeem! returns nil for a wrong code" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "x")
    code = authorization.approve!

    assert_nil authorization.redeem!(code == "000000" ? "111111" : "000000")
  end

  test "redeem! returns nil for an expired code" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "x")
    authorization.approve!
    authorization.update!(code_expires_at: 1.minute.ago)

    assert_nil authorization.redeem!("000000")
  end
end
