require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  test "handlers_for returns concrete handlers for a service kind" do
    handlers = ApplicationTool.handlers_for("github")

    assert_includes handlers, Github::ListIssuesTool
    refute_includes handlers, Github::Base
  end

  test "expose_for binds one class per handler to the service" do
    bound = ApplicationTool.expose_for(services(:github_prod))

    assert_equal 1, bound.length

    klass = bound.first

    assert_equal services(:github_prod).id, klass.service_id
    assert_equal "github_list_issues", klass.tool_name
    assert klass < Github::ListIssuesTool
  end

  test "appends the service slug when a workspace has more than one service of the same kind" do
    Current.workspace = workspaces(:one)

    bound = ApplicationTool.expose_for(services(:github_prod))
    assert_equal "github_list_issues_prod", bound.first.tool_name

    Current.workspace = nil
  ensure
    Current.workspace = nil
  end

  test "bound classes keep the handler's schema and description" do
    klass = ApplicationTool.expose_for(services(:github_prod)).first

    assert_equal "List issues for a repository", klass.description
    schema = klass.input_schema_to_json
    assert_includes schema.fetch(:required), "repo"
    assert schema.dig(:properties, :repo, :type) == "string"
  end

  test "tool_key is the handler kind for non-remote tools" do
    assert_equal "list_issues", Github::ListIssuesTool.tool_key
    assert_equal "list_issues", ApplicationTool.expose_for(services(:github_prod)).first.tool_key
  end

  test "tool_key is the remote name for proxied MCP tools" do
    service = Services::Mcp.new(name: "Search")
    service.config = { url: "https://example.com/mcp", headers: "{}" }

    fake = Object.new
    def fake.list_tools
      { "tools" => [ { "name" => "web_search", "description" => "d", "inputSchema" => {} } ] }
    end
    service.instance_variable_set(:@client, fake)
    Rails.cache.delete([ "mcp_remote_tools", service.config[:url] ])

    assert_equal "web_search", ApplicationTool.expose_for(service).first.tool_key
  end

  test "call blocks a tool the workspace does not allow" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: ["resume_items"])
    Current.workspace = join.workspace

    tool = ApplicationTool.expose_for(join.service).find { |t| t.kind == "get_episodes" }.new

    assert_raises(ApplicationTool::NotAllowedToolError) { tool.send(:authorize_call!) }
  ensure
    Current.workspace = nil
  end

  test "authorize allows a permitted tool" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: ["resume_items"])
    Current.workspace = join.workspace

    tool = ApplicationTool.expose_for(join.service).find { |t| t.kind == "resume_items" }.new

    assert_nothing_raised { tool.send(:authorize_call!) }
  ensure
    Current.workspace = nil
  end

  test "call is always allowed for generic tools" do
    Current.workspace = workspaces(:one)

    tool = SampleTool.new

    assert_nothing_raised { tool.send(:authorize_call!) }
  ensure
    Current.workspace = nil
  end

  test "bound class does not mutate the shared handler" do
    original_name = Github::ListIssuesTool.tool_name

    ApplicationTool.expose_for(services(:github_prod))

    assert_equal original_name, Github::ListIssuesTool.tool_name
    assert_not Github::ListIssuesTool.respond_to?(:service_id)
  end

  test "expose_for an mcp service builds one class per remote tool" do
    service = Services::Mcp.new(name: "Search")
    service.config = { url: "https://example.com/mcp", headers: "{}" }

    fake = Object.new
    def fake.list_tools
      {
        "tools" => [
          { "name" => "web_search", "description" => "Search the web",
            "inputSchema" => { "type" => "object", "properties" => { "q" => { "type" => "string" } }, "required" => [ "q" ] } },
          { "name" => "web_fetch", "description" => "Fetch a URL", "inputSchema" => {} }
        ]
      }
    end
    service.instance_variable_set(:@client, fake)
    Rails.cache.delete([ "mcp_remote_tools", service.config[:url] ])

    klass, klass2 = ApplicationTool.expose_for(service)

    assert_equal "web_search", klass.tool_name
    assert_equal "web_search", klass.remote_tool_name
    assert klass < Mcp::Base

    assert_equal "web_fetch", klass2.tool_name
    schema = klass.input_schema_to_json
    assert_equal "object", schema[:type]
    assert_equal %w[q], schema[:required]
  end
end
