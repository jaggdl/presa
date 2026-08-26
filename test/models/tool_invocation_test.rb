require "test_helper"

class ToolInvocationTest < ActiveSupport::TestCase
  test "record! stores an invocation for the given token" do
    ApiToken.issue!(workspace: workspaces(:one), name: "Cursor")
    token = workspaces(:one).api_tokens.active.take

    assert_difference -> { ToolInvocation.count }, 1 do
      ToolInvocation.record!(
        api_token: token,
        service: services(:github_prod),
        tool_name: "github_list_issues_prod",
        arguments: { repo: "org/repo" },
        response: { content: "ok" },
        status: "success",
        duration_ms: 42
      )
    end

    record = ToolInvocation.last
    assert_equal workspaces(:one), record.workspace
    assert_equal "Cursor", record.api_token.name
    assert_equal "github_list_issues_prod", record.tool_name
    assert_equal({ "repo" => "org/repo" }, record.arguments)
    assert record.success?
  end

  test "record! is a no-op without a token" do
    assert_no_difference -> { ToolInvocation.count } do
      ToolInvocation.record!(tool_name: "foo", arguments: {})
    end
  end

  test "truncate caps oversized responses" do
    oversized = { "data" => "x" * 100_000 }

    assert_operator ToolInvocation.truncate(oversized).to_json.bytesize, :<=, ToolInvocation::RESULT_CAP
  end

  test "for_workspace scopes by the token's workspace" do
    ApiToken.issue!(workspace: workspaces(:one), name: "t1")
    ApiToken.issue!(workspace: workspaces(:two), name: "t2")
    token_one = workspaces(:one).api_tokens.active.take
    token_two = workspaces(:two).api_tokens.active.take
    ToolInvocation.record!(api_token: token_one, tool_name: "a", arguments: {})
    ToolInvocation.record!(api_token: token_two, tool_name: "b", arguments: {})

    names = ToolInvocation.for_workspace(workspaces(:one)).pluck(:tool_name)
    assert_equal [ "a" ], names
  end
end
