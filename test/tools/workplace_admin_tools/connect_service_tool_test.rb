# frozen_string_literal: true

require "test_helper"

class WorkplaceAdminToolsConnectServiceToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace services" do
    kinds = ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind)
    assert_includes kinds, "connect_service"
  end

  test "links a service to a managed workspace" do
    ws = workspaces(:one)
    service = services(:places)
    tool = expose_workspace_tool("connect_service", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id, service_id: service.id)

    assert ws.workspace_services.exists?(service: service)
    assert_equal true, result[:connected]
  end

  test "is idempotent when already connected" do
    ws = workspaces(:one)
    service = services(:seerr)
    tool = expose_workspace_tool("connect_service", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id, service_id: service.id)
    assert_equal true, result[:connected]
  end

  test "rejects a workspace not managed by the service" do
    tool = expose_workspace_tool("connect_service", workspaces: [ workspaces(:one) ])
    assert_raises(ArgumentError) { tool.call(workspace_id: workspaces(:one_second).id, service_id: services(:places).id) }
  end
end
