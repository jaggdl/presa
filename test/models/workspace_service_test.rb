require "test_helper"

class WorkspaceServiceTest < ActiveSupport::TestCase
  test "links a service to a workspace" do
    join = workspace_services(:one_github_prod)

    assert_equal workspaces(:one), join.workspace
    assert_equal services(:github_prod), join.service
  end

  test "rejects a service from another team" do
    join = WorkspaceService.new(workspace: workspaces(:one), service: services(:other_user_service))

    assert_not join.valid?
    assert_includes join.errors[:service], "must belong to the same team as the workspace"
  end

  test "unset allowed_tools reads as everything allowed" do
    join = workspace_services(:one_github_prod)

    assert_equal [ WorkspaceService::ALLOW_ALL ], join.allowed_tools
    assert join.all_tools_allowed?
    assert join.tool_allowed?("list_issues")
  end

  test "allowed_tools can be restricted to a subset" do
    join = workspace_services(:one_github_prod)
    join.allowed_tools = [ "list_issues" ]

    assert_equal [ "list_issues" ], join.allowed_tools
    assert_not join.all_tools_allowed?
    assert join.tool_allowed?("list_issues")
    assert_not join.tool_allowed?("other")
  end

  test "deselecting every tool allows nothing" do
    join = workspace_services(:one_github_prod)
    join.allowed_tools = []

    assert_equal [], join.allowed_tools
    assert_not join.all_tools_allowed?
    assert_not join.tool_allowed?("list_issues")
  end

  test "explicit star sentinel means everything allowed" do
    join = workspace_services(:one_github_prod)
    join.allowed_tools = [ WorkspaceService::ALLOW_ALL ]

    assert_equal [ WorkspaceService::ALLOW_ALL ], join.allowed_tools
    assert join.all_tools_allowed?
  end

  test "allowed_tools round-trips through the database" do
    join = workspace_services(:one_github_prod)
    join.allowed_tools = [ "list_issues", "create_comment" ]
    join.save!

    assert_equal [ "list_issues", "create_comment" ], join.reload.allowed_tools
  end
end
