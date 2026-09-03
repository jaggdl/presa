# frozen_string_literal: true

require "test_helper"

class ReadWorkspaceAllowedToolsToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace tool services" do
    assert_includes ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind), "read_workspace_allowed_tools"
  end

  test "reports allowed tools per connected service" do
    ws = workspaces(:one)
    service = services(:seerr)
    join = ws.workspace_services.find_by!(service: service)
    join.update!(allowed_tools: [ "search" ])
    tool = expose_workspace_tool("read_workspace_allowed_tools", workspaces: [ ws ])

    result = tool.call(workspace_id: ws.id)

    entry = result[:services].find { |s| s[:service_id] == service.id }
    refute_nil entry
    assert_equal service.name, entry[:service_name]
    assert_equal "seerr", entry[:kind]
    assert_equal [ "search" ], entry[:allowed_tools]
    assert_equal false, entry[:all_allowed]
  end
end
