require "test_helper"

class ApplicationToolTest < ActiveSupport::TestCase
  test "handlers_for returns concrete handlers for a service kind" do
    handlers = ApplicationTool.handlers_for("github")

    assert_includes handlers, Tools::Github::ListIssues
    refute_includes handlers, Tools::Github::Base
  end

  test "expose_for binds one class per handler to the service" do
    bound = ApplicationTool.expose_for(services(:github_prod))

    assert_equal 1, bound.length

    klass = bound.first

    assert_equal services(:github_prod).id, klass.service_id
    assert_equal "github_list_issues", klass.tool_name
    assert klass < Tools::Github::ListIssues
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

  test "bound class does not mutate the shared handler" do
    original_name = Tools::Github::ListIssues.tool_name

    ApplicationTool.expose_for(services(:github_prod))

    assert_equal original_name, Tools::Github::ListIssues.tool_name
    assert_not Tools::Github::ListIssues.respond_to?(:service_id)
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
    assert klass < Tools::Mcp::Base

    assert_equal "web_fetch", klass2.tool_name
    schema = klass.input_schema_to_json
    assert_equal "object", schema[:type]
    assert_equal %w[q], schema[:required]
  end
end
