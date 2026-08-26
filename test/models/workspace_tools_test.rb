require "test_helper"

class WorkspaceToolsTest < ActiveSupport::TestCase
  test "tool_result_text passes strings through verbatim" do
    assert_equal "hello\n", Workspace.new.tool_result_text("hello")
  end

  test "tool_result_text passes a hash through as-is" do
    hash = { "name" => "pix", "count" => 2 }
    assert_equal "#{hash}\n", Workspace.new.tool_result_text(hash)
  end

  test "tool_result_text renders nil as OK" do
    assert_equal "OK\n", Workspace.new.tool_result_text(nil)
  end

  test "tool_result_text unwraps the MCP content envelope" do
    envelope = { "content" => [ { "type" => "text", "text" => "hello bot" } ] }
    assert_equal "hello bot\n", Workspace.new.tool_result_text(envelope)
  end

  test "tool_result_text unwraps the envelope and passes the inner JSON through" do
    result = { "content" => [ { "type" => "text", "text" => '{"name":"pix","count":2}' } ] }
    assert_equal '{"name":"pix","count":2}' + "\n", Workspace.new.tool_result_text(result)
  end

  test "tool_result_text leaves a non-JSON string untouched" do
    assert_equal "plain text\n", Workspace.new.tool_result_text("plain text")
  end

  test "allowed_tools only exposes tools allowed for the workspace" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    workspace = join.workspace

    names = workspace.allowed_tools.map(&:tool_key)
    assert_includes names, "resume_items"
    refute_includes names, "get_episodes"
  end

  test "find_allowed_tool finds by exposed name or returns nil" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    workspace = join.workspace

    Current.workspace = workspace
    name = workspace.allowed_tools.find { |t| t.tool_key == "resume_items" }.tool_name

    assert_equal name, workspace.find_allowed_tool(name).tool_name
    assert_nil workspace.find_allowed_tool("jellyfin_get_episodes")
  ensure
    Current.workspace = nil
  end

  test "execute_tool_text raises UnknownTool for a forbidden tool" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    workspace = join.workspace

    assert_raises(WorkspaceTools::UnknownTool) do
      workspace.execute_tool_text("jellyfin_get_episodes", "{}")
    end
  end

  test "execute_tool_text raises InvalidToolBody for malformed JSON" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    workspace = join.workspace
    Current.workspace = workspace
    name = workspace.allowed_tools.find { |t| t.tool_key == "resume_items" }.tool_name

    assert_raises(WorkspaceTools::InvalidToolBody) do
      workspace.execute_tool_text(name, "{not json")
    end
  ensure
    Current.workspace = nil
  end

  test "parse_tool_arguments turns a blank body into no args" do
    assert_equal({}, Workspace.new.parse_tool_arguments(""))
    assert_equal({ repo: "foo" }, Workspace.new.parse_tool_arguments('{"repo":"foo"}'))
  end
end
