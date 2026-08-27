require "test_helper"

class Bots::AuthorizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = workspaces(:one)
    @user = @workspace.user
    @share_code = @workspace.reset_share_code!
  end

  def authorize_body(name: "coder", justification: "invoices", share_code: @share_code)
    { name: name, justification: justification, share_code: share_code }
  end

  def json_body
    JSON.parse(response.body)
  end

  test "POST authorize creates a pending request and returns request_id + URL" do
    post bots_authorize_path, params: authorize_body, as: :json

    assert_response :success
    body = json_body
    assert body["request_id"].present?
    assert_includes body["authorize_url"], "/bots/authorizations/"
    assert BotAuthorization.find_by(request_token: body["request_id"]).pending?
  end

  test "POST authorize rejects a bad or missing share code" do
    post bots_authorize_path, params: authorize_body(share_code: "wrong"), as: :json
    assert_response :unauthorized
  end

  test "POST authorize requires a name" do
    post bots_authorize_path, params: { share_code: @share_code }, as: :json
    assert_response :unprocessable_entity
    refute BotAuthorization.any?
  end

  test "owner can approve and get a code, then agent redeems it for a token" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "coder")
    sign_in_as @user

    post approve_bots_authorization_path(authorization.request_token)

    assert_response :success
    code = response.body[%r{<pre[^>]*>(\d{10})</pre>}, 1]
    assert_match(/\A\d{10}\z/, code)

    post token_bots_authorization_path(authorization.request_token), params: { code: code }, as: :json

    assert_response :success
    assert_match(/\Amcp_/, json_body["token"])
    assert authorization.reload.consumed?
  end

  test "token endpoint rejects a wrong code" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "coder")
    sign_in_as @user
    post approve_bots_authorization_path(authorization.request_token)
    code = response.body[%r{<pre[^>]*>(\d{10})</pre>}, 1]
    refute_nil code

    post token_bots_authorization_path(authorization.request_token), params: { code: "000000" }, as: :json

    assert_response :unauthorized
  end

  test "non-owner cannot approve" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "coder")
    sign_in_as users(:two)

    post approve_bots_authorization_path(authorization.request_token)

    assert_response :not_found
  end

  test "anonymous user is redirected to the login page on show" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "coder")

    get bots_authorization_path(authorization.request_token)

    assert_redirected_to new_session_path
  end

  test "token endpoint is rate-limited per IP" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "coder")
    sign_in_as @user
    post approve_bots_authorization_path(authorization.request_token)

    11.times do
      post token_bots_authorization_path(authorization.request_token), params: { code: "0000000000" }, as: :json
    end

    assert_response :too_many_requests
  end

  test "approving an already-approved request reissues a fresh code" do
    authorization = BotAuthorization.initiate!(workspace: @workspace, name: "coder")
    sign_in_as @user

    post approve_bots_authorization_path(authorization.request_token)
    first_code = response.body[%r{<pre[^>]*>(\d{10})</pre>}, 1]

    post approve_bots_authorization_path(authorization.request_token)
    second_code = response.body[%r{<pre[^>]*>(\d{10})</pre>}, 1]

    assert_match(/\A\d{10}\z/, first_code)
    assert_match(/\A\d{10}\z/, second_code)
    assert authorization.reload.approved?
  end
end
