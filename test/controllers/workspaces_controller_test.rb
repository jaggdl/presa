require "test_helper"

class WorkspacesControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "index requires authentication" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "index lists the signed-in user's workspaces" do
    sign_in_as @user

    get root_path

    assert_response :success
    assert_select "a", text: "Workspace One"
    assert_select "a", text: "Workspace Two", count: 0
  end

  test "new requires authentication" do
    get new_workspace_path

    assert_redirected_to new_session_path
  end

  test "new renders the form" do
    sign_in_as @user

    get new_workspace_path

    assert_response :success
  end

  test "create builds a workspace for the current user" do
    sign_in_as @user

    assert_difference -> { @user.workspaces.count }, 1 do
      post workspaces_path, params: { workspace: { name: "New WS" } }
    end

    assert_redirected_to workspace_path(@user.workspaces.order(:created_at).last)
  end

  test "show displays tool invocations" do
    sign_in_as @user
    workspace = workspaces(:one)
    token = ApiToken.issue!(workspace: workspace, name: "Cursor")
    invocation_token = workspace.api_tokens.active.take
    ToolInvocation.record!(api_token: invocation_token, service: services(:github_prod), tool_name: "github_list_issues_prod", arguments: { repo: "org/repo" })

    get workspace_path(workspace)

    assert_response :success
    assert_select "li span", text: "github_list_issues_prod"
  end

  test "invocations appends older rows via turbo stream" do
    sign_in_as @user
    workspace = workspaces(:one)
    token = ApiToken.create!(workspace: workspace, token_digest: "digest")
    older = ToolInvocation.create!(api_token: token, tool_name: "old_tool", arguments: {})
    newer = ToolInvocation.create!(api_token: token, tool_name: "new_tool", arguments: {})

    get invocations_workspace_path(workspace, before_id: newer.id),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/turbo-stream action="append"/, response.body)
    assert_match(/target="tool-invocations"/, response.body)
    assert_match(/old_tool/, response.body)
    refute_match(/new_tool/, response.body)
  end

  test "create renders errors on invalid input" do
    sign_in_as @user

    assert_no_difference -> { @user.workspaces.count } do
      post workspaces_path, params: { workspace: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "show requires authentication" do
    get workspace_path(workspaces(:one))

    assert_redirected_to new_session_path
  end

  test "show displays the workspace and its API tokens" do
    sign_in_as @user
    workspace = workspaces(:one)
    workspace.api_tokens.create!(token_digest: "digest", name: "Cursor")

    get workspace_path(workspace)

    assert_response :success
    assert_select "h1", text: "Workspace One"
    assert_select "div span", text: "Cursor"
  end

  test "show does not expose another user's workspace" do
    sign_in_as @user

    get workspace_path(workspaces(:two))

    assert_response :not_found
  end
end
