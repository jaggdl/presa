require "test_helper"

class InvocationBroadcastJobTest < ActionCable::TestCase
  setup do
    @api_token = ApiToken.create!(workspace: workspaces(:one), token_digest: "digest")
    @invocation = ToolInvocation.create!(
      api_token: @api_token,
      tool_name: "github_list_issues",
      arguments: { "repo" => "org/repo" },
      status: "success"
    )
    @stream = "invocations_#{@invocation.workspace.id}"
  end

  test "rendered payload targets the invocation list and includes the tool name" do
    InvocationBroadcastJob.perform_now(@invocation)

    message = ActiveSupport::JSON.decode(broadcasts(@stream).first)
    assert message
    assert_includes message, "turbo-stream action=\"prepend\""
    assert_includes message, "target=\"tool-invocations\""
    assert_includes message, "github_list_issues"
    assert_includes message, "turbo-stream action=\"remove\" target=\"tool-invocations-empty\""
  end
end
