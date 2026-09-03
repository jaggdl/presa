# frozen_string_literal: true

require "test_helper"

class WorkplaceAdminToolsDisconnectServiceToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace services" do
    kinds = ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind)
    assert_includes kinds, "disconnect_service"
  end

  test "removes a service from a managed workspace" do
    ws = workspaces(:one)
    service = services(:places)
    tool = expose_workspace_tool("disconnect_service", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id, service_id: service.id)

    assert_not ws.workspace_services.exists?(service: service)
    assert_equal false, result[:connected]
  end

  test "raises when the service is not connected" do
    tool = expose_workspace_tool("disconnect_service", workspaces: [ workspaces(:one) ])
    assert_raises(ArgumentError) { tool.call(workspace_id: workspaces(:one).id, service_id: services(:google_calendar).id) }
  end
end
