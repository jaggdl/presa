# frozen_string_literal: true

require "test_helper"

class ReadWorkspaceServicesToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace tools services" do
    assert_includes ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind), "read_workspace_services"
  end

  test "reports connected and addable services" do
    ws = workspaces(:one)
    connected = services(:places)
    addable = services(:google_calendar)
    tool = expose_workspace_tool("read_workspace_services", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id)

    assert_includes result[:connected_services].map { |s| s[:id] }, connected.id
    assert_includes result[:addable_services].map { |s| s[:id] }, addable.id
    assert result[:addable_services].none? { |s| s[:id] == connected.id }
  end
end
