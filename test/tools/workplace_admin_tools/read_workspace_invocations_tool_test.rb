# frozen_string_literal: true

require "test_helper"

class ReadWorkspaceInvocationsToolTest < ActiveSupport::TestCase
  include WorkspaceToolsTestHelper

  test "is exposed for workspace tools services" do
    assert_includes ApplicationTool.expose_for(services(:workspace_manager)).map(&:kind), "read_workspace_invocations"
  end

  test "returns the workspace's recent tool invocations" do
    ws = workspaces(:one)
    ws_other = workspaces(:one_second)
    ApiToken.issue!(workspace: ws, name: "w-tox")
    ApiToken.issue!(workspace: ws_other, name: "other")
    ToolInvocation.record!(api_token: ws.api_tokens.active.take, service: services(:github_prod), tool_name: "github_list_issues_prod", arguments: {})
    ToolInvocation.record!(api_token: ws.api_tokens.active.take, service: services(:seerr), tool_name: "seerr_search", arguments: {})
    ToolInvocation.record!(api_token: ws_other.api_tokens.active.take, tool_name: "other_tool", arguments: {})

    tool = expose_workspace_tool("read_workspace_invocations", workspaces: [ ws, ws_other ])
    result = tool.call(workspace_id: ws.id)

    names = result[:invocations].map { |i| i[:tool_name] }
    assert_includes names, "github_list_issues_prod"
    assert_includes names, "seerr_search"
    assert_not_includes names, "other_tool"
  end
end
