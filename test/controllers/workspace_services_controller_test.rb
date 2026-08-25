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
end
