require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  test "handlers_for returns concrete handlers for a service kind" do
    handlers = ApplicationTool.handlers_for("places")

    assert_includes handlers, Places::TextSearchTool
    refute_includes handlers, Places::Base
  end

  test "expose_for binds one class per handler to the service" do
    bound = ApplicationTool.expose_for(services(:places))

    assert_equal ApplicationTool.handlers_for("places").length, bound.length

    klass = bound.find { |t| t.kind == "text_search" }

    assert_equal services(:places).id, klass.service_id
    assert_equal "places_text_search", klass.tool_name
    assert klass < Places::TextSearchTool
  end

  test "appends the service slug when a workspace has more than one service of the same kind" do
    Current.workspace = workspaces(:one)
    join = workspace_services(:one_places)

    # Workspace :one has two github MCP services; a Places tool must stay
    # distinct. Use the github service pair to prove slug disambiguation.
    service = services(:github_prod)
    def service.remote_tools
      [ { "name" => "web_search", "inputSchema" => {} } ]
    end

    bound = ApplicationTool.expose_for(service)
    assert_equal "prod_web_search", bound.first.tool_name

    Current.workspace = nil
  ensure
    Current.workspace = nil
  end

  test "bound classes keep the handler's schema and description" do
    klass = ApplicationTool.expose_for(services(:places)).find { |t| t.kind == "text_search" }

    assert_equal "Search for places by a free-text query (e.g. 'coffee near Union Square')", klass.description
  end

  test "tool_key is the handler kind for non-remote tools" do
    assert_equal "text_search", Places::TextSearchTool.tool_key
    assert_equal "text_search", ApplicationTool.expose_for(services(:places)).find { |t| t.kind == "text_search" }.tool_key
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
    join = workspace_services(:one_places)
    join.update!(allowed_tools: [ "text_search" ])
    Current.workspace = join.workspace

    tool = ApplicationTool.expose_for(join.service).find { |t| t.kind == "place_details" }.new

    assert_raises(ApplicationTool::NotAllowedToolError) { tool.send(:authorize_call!) }
  ensure
    Current.workspace = nil
  end

  test "authorize allows a permitted tool" do
    join = workspace_services(:one_places)
    join.update!(allowed_tools: [ "text_search" ])
    Current.workspace = join.workspace

    tool = ApplicationTool.expose_for(join.service).find { |t| t.kind == "text_search" }.new

    assert_nothing_raised { tool.send(:authorize_call!) }
  ensure
    Current.workspace = nil
  end

  test "call is always allowed for generic tools" do
    Current.workspace = workspaces(:one)

    generic = Class.new(ApplicationTool)

    assert_nothing_raised { generic.new.send(:authorize_call!) }
  ensure
    Current.workspace = nil
  end

  test "bound class does not mutate the shared handler" do
    original_name = Places::TextSearchTool.tool_name

    ApplicationTool.expose_for(services(:places))

    assert_equal original_name, Places::TextSearchTool.tool_name
    assert_not Places::TextSearchTool.respond_to?(:service_id)
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

  test "record_invocation logs payloads when log_tool_data is enabled" do
    workspace = workspaces(:one)
    workspace.update!(log_tool_data: true)
    ApiToken.issue!(workspace: workspace, name: "Cursor")
    token = workspace.api_tokens.active.take
    Current.workspace = workspace
    Current.api_token = token

    tool = ApplicationTool.expose_for(services(:places)).find { |t| t.kind == "text_search" }.new
    tool.send(:record_invocation,
              args: { limit: 5 }, result: { content: "ok" }, status: "success", duration_ms: 10)

    record = ToolInvocation.last
    assert_equal({ "limit" => 5 }, record.arguments)
    assert_equal({ "content" => "ok" }, record.response)
  ensure
    Current.workspace = nil
    Current.api_token = nil
  end

  test "record_invocation strips payloads when log_tool_data is disabled" do
    workspace = workspaces(:one)
    workspace.update!(log_tool_data: false)
    ApiToken.issue!(workspace: workspace, name: "Cursor")
    token = workspace.api_tokens.active.take
    Current.workspace = workspace
    Current.api_token = token

    tool = ApplicationTool.expose_for(services(:places)).find { |t| t.kind == "text_search" }.new
    tool.send(:record_invocation,
              args: { limit: 5 }, result: { content: "ok" }, status: "error",
              error_message: "boom", duration_ms: 10)

    record = ToolInvocation.last
    assert_nil record.arguments
    assert_nil record.response
    assert_nil record.error_message
    assert_equal "error", record.status
    assert_equal "places_text_search", record.tool_name
  ensure
    Current.workspace = nil
    Current.api_token = nil
  end
end
