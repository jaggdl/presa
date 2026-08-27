require "test_helper"

class WorkspaceServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @workspace = workspaces(:one)
    sign_in_as @user
  end

  test "create attaches a service to the workspace" do
    service = @user.services.create!(name: "Other", type: "Services::Github", config: { api_token: "tok" })

    assert_difference -> { @workspace.workspace_services.count }, 1 do
      post workspace_workspace_services_path(@workspace), params: { service_id: service.id }
    end

    assert_redirected_to workspace_path(@workspace)
  end

  test "create does not attach another user's service" do
    other = services(:other_user_service)

    assert_no_difference -> { @workspace.workspace_services.count } do
      post workspace_workspace_services_path(@workspace), params: { service_id: other.id }
    end
  end

  test "destroy removes the join" do
    join = workspace_services(:one_github_prod)

    assert_difference -> { @workspace.workspace_services.count }, -1 do
      delete workspace_workspace_service_path(@workspace, join.service_id)
    end

    assert_redirected_to workspace_path(@workspace)
    assert_raises(ActiveRecord::RecordNotFound) { join.reload }
  end

  test "show renders the allowed tools form" do
    join = workspace_services(:one_github_prod)

    get workspace_workspace_service_path(@workspace, join)

    assert_response :success
    assert_select "form[action=?]", workspace_workspace_service_path(@workspace, join)
    assert_select "[data-controller=allowed-tools]"
    assert_select "[data-allowed-tools-target='checkbox']", minimum: 1
  end

  test "update persists the allowed tool subset" do
    join = workspace_services(:one_jellyfin)
    available = ApplicationTool.expose_for(join.service).map { |t| t.tool_key.to_s }
    subset = available.first(1)

    assert_operator available.length, :>, 1, "expected a multi-tool fixture service"
    patch workspace_workspace_service_path(@workspace, join), params: {
      workspace_service: { allowed_tools: subset }
    }

    assert_redirected_to workspace_workspace_service_path(@workspace, join)
    assert_equal subset, join.reload.allowed_tools
  end

  test "update selecting every tool stores the star sentinel" do
    join = workspace_services(:one_github_prod)
    available = ApplicationTool.expose_for(join.service).map { |t| t.tool_key.to_s }

    patch workspace_workspace_service_path(@workspace, join), params: {
      workspace_service: { allowed_tools: available }
    }

    assert_equal [WorkspaceService::ALLOW_ALL], join.reload.allowed_tools
  end
end
