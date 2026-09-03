# frozen_string_literal: true

require "test_helper"

class WorkplaceAdminToolsSetWorkspaceAllowedToolsToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace services" do
    kinds = ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind)
    assert_includes kinds, "set_workspace_allowed_tools"
  end

  test "restricts a service to the given tool names" do
    ws = workspaces(:one)
    service = services(:places)
    join = ws.workspace_services.find_by!(service: service)
    tool = expose_workspace_tool("set_workspace_allowed_tools", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id, service_id: service.id, all: false, allowed_tools: [ "text_search" ])

    assert_equal false, join.reload.all_tools_allowed?
    assert_equal [ "text_search" ], join.allowed_tools
    assert_equal false, result[:all_allowed]
  end

  test "allows every tool when all is true" do
    ws = workspaces(:one)
    service = services(:places)
    join = ws.workspace_services.find_by!(service: service)
    join.update!(allowed_tools: [ "text_search" ])
    tool = expose_workspace_tool("set_workspace_allowed_tools", workspaces: [ ws ])

    tool.call(workspace_id: ws.id, service_id: service.id, all: true)

    assert join.reload.all_tools_allowed?
  end
end
