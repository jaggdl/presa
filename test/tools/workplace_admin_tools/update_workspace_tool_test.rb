# frozen_string_literal: true

require "test_helper"

class WorkplaceAdminToolsUpdateWorkspaceToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace services" do
    kinds = ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind)
    assert_includes kinds, "update_workspace"
  end

  test "updates the workspace name and description" do
    ws = workspaces(:one)
    tool = expose_workspace_tool("update_workspace", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id, name: "Renamed", description: "A new description")

    assert_equal "Renamed", ws.reload.name
    assert_equal "A new description", ws.description
    assert_equal "Renamed", result[:name]
  end

  test "rejects a workspace not managed by the service" do
    tool = expose_workspace_tool("update_workspace", workspaces: [ workspaces(:one) ])
    assert_raises(ArgumentError) { tool.call(workspace_id: workspaces(:one_second).id, name: "Nope") }
  end
end
