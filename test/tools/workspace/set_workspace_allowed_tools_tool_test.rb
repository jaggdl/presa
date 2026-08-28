# frozen_string_literal: true

require "test_helper"

class WorkspaceToolsSetWorkspaceAllowedToolsToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace services" do
    kinds = ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind)
    assert_includes kinds, "set_workspace_allowed_tools"
  end

  test "restricts a service to the given tool names" do
    ws = workspaces(:one)
    service = services(:jellyfin)
    join = ws.workspace_services.find_by!(service: service)
    tool = expose_workspace_tool("set_workspace_allowed_tools", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id, service_id: service.id, all: false, tool_keys: [ "next_up" ])

    assert_equal false, join.reload.all_tools_allowed?
    assert_equal [ "next_up" ], join.allowed_tools
    assert_equal false, result[:all_allowed]
  end

  test "allows every tool when all is true" do
    ws = workspaces(:one)
    service = services(:jellyfin)
    join = ws.workspace_services.find_by!(service: service)
    join.update!(allowed_tools: [ "next_up" ])
    tool = expose_workspace_tool("set_workspace_allowed_tools", workspaces: [ ws ])

    tool.call(workspace_id: ws.id, service_id: service.id, all: true)

    assert join.reload.all_tools_allowed?
  end
end
