require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @workspace = workspaces(:one)
  end

  test "create requires authentication" do
    post workspace_api_tokens_path(@workspace), params: { api_token: { name: "Cursor" } }

    assert_redirected_to new_session_path
  end

  test "create issues a token into the workspace and shows it once" do
    sign_in_as @user

    assert_difference -> { @workspace.api_tokens.count }, 1 do
      post workspace_api_tokens_path(@workspace), params: { api_token: { name: "Cursor" } }
    end

    assert_redirected_to workspace_path(@workspace)
    assert_match(/\Amcp_[A-Za-z0-9]{32}\z/, flash[:token])
  end

  test "create does not issue into another user's workspace" do
    sign_in_as @user
    other_workspace = workspaces(:two)

    post workspace_api_tokens_path(other_workspace), params: { api_token: { name: "Cursor" } }

    assert_response :not_found
    assert_equal 0, other_workspace.api_tokens.count
  end

  test "destroy revokes a token" do
    sign_in_as @user
    api_token = @workspace.api_tokens.create!(token_digest: "digest")

    assert_difference -> { @workspace.api_tokens.active.count }, -1 do
      delete workspace_api_token_path(@workspace, api_token)
    end

    assert_redirected_to workspace_path(@workspace)
    assert api_token.reload.revoked?
  end

  test "destroy does not revoke another workspace's token" do
    sign_in_as @user
    other_workspace = workspaces(:two)
    other_token = other_workspace.api_tokens.create!(token_digest: "digest")

    delete workspace_api_token_path(other_workspace, other_token)

    assert_response :not_found
    assert_not other_token.reload.revoked?
  end
end
