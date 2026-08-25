require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "index requires authentication" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "index lists the signed-in user's tokens" do
    sign_in_as @user
    token = ApiToken.issue!(user: @user, name: "Cursor")

    get root_path

    assert_response :success
    assert_select "td", text: "Cursor"
  end

  test "create issues a token and shows it once" do
    sign_in_as @user

    assert_difference -> { @user.api_tokens.count }, 1 do
      post api_tokens_path, params: { api_token: { name: "Cursor" } }
    end

    assert_redirected_to root_path
    assert_match(/\Amcp_[A-Za-z0-9]{32}\z/, flash[:token])
  end

  test "destroy revokes a token" do
    sign_in_as @user
    api_token = ApiToken.issue!(user: @user, name: "Cursor")
    api_token = @user.api_tokens.take

    assert_difference -> { @user.api_tokens.active.count }, -1 do
      delete api_token_path(api_token)
    end

    assert_redirected_to root_path
    assert api_token.reload.revoked?
  end

  test "destroy does not revoke another user's token" do
    sign_in_as @user
    ApiToken.issue!(user: users(:two))
    other_token = users(:two).api_tokens.take

    delete api_token_path(other_token)

    assert_response :not_found
    assert_not other_token.reload.revoked?
  end
end
