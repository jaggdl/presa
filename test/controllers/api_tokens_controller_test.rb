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

  test "create responds with a turbo stream appending the client and showing the token" do
    sign_in_as @user

    post workspace_api_tokens_path(@workspace),
         params: { api_token: { name: "Cursor" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/turbo-stream action="prepend"/, response.body)
    assert_match(/target="client_form"/, response.body)
    assert_match(/data-controller="tabs"/, response.body)
    assert_match(/claude_desktop_config/, response.body)
    assert_match(/supergateway/, response.body)
    assert_match(/\Amcp_[A-Za-z0-9]{32}\z/, response.body.match(/select-all[^>]*>(.*?)<\/pre>/m)[1])
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

  test "update renames a token" do
    sign_in_as @user
    api_token = @workspace.api_tokens.create!(token_digest: "digest", name: "Cursor")

    patch workspace_api_token_path(@workspace, api_token), params: { api_token: { name: "Windsurf" } }

    assert_redirected_to workspace_path(@workspace)
    assert_equal "Windsurf", api_token.reload.name
  end

  test "update with a blank name makes the token unnamed" do
    sign_in_as @user
    api_token = @workspace.api_tokens.create!(token_digest: "digest", name: "Cursor")

    patch workspace_api_token_path(@workspace, api_token), params: { api_token: { name: "" } }

    assert_redirected_to workspace_path(@workspace)
    assert_nil api_token.reload.name
  end

  test "update does not rename another workspace's token" do
    sign_in_as @user
    other_workspace = workspaces(:two)
    other_token = other_workspace.api_tokens.create!(token_digest: "digest", name: "Cursor")

    patch workspace_api_token_path(other_workspace, other_token), params: { api_token: { name: "Windsurf" } }

    assert_response :not_found
    assert_equal "Cursor", other_token.reload.name
  end
end
