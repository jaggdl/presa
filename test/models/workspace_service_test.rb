require "test_helper"

class WorkspaceServiceTest < ActiveSupport::TestCase
  test "links a service to a workspace" do
    join = workspace_services(:one_github_prod)

    assert_equal workspaces(:one), join.workspace
    assert_equal services(:github_prod), join.service
  end

  test "rejects a service from another user" do
    join = WorkspaceService.new(workspace: workspaces(:one), service: services(:other_user_service))

    assert_not join.valid?
    assert_includes join.errors[:service], "must belong to the same user as the workspace"
  end
end
