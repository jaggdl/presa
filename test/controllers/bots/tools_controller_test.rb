require "test_helper"

class Bots::ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = workspaces(:one)
    @user = @workspace.user
    @base_url = ENV["BASE_URL"].presence || "http://www.example.com"
  end

  test "GET /bots/tools requires a bearer token" do
    get bots_tools_path

    assert_response :unauthorized
  end

  test "GET /bots/SKILL.md is unauthenticated and returns the skill file" do
    get bots_skill_path

    assert_response :success
    assert_includes response.content_type, "text/markdown"
    assert_includes response.body, "name: presa-bot-api" # frontmatter
    assert_includes response.body, "presa login"
    assert_includes response.body, "presa run"
    assert_includes response.body, "#{@base_url}/bots/client/install.sh" # base_url interpolated
    refute_includes response.body, "jellyfin"
    refute_includes response.body, "search_workflows"
    refute_includes response.body, "<your-presa-url>"
  end

  test "GET /bots/SKILL.md includes install and token-storage guidance" do
    get bots_skill_path

    assert_response :success
    assert_includes response.body, "## Installation"
    assert_includes response.body, "client/install.sh"
    assert_includes response.body, "Never echo, log, or display the API token or the share code"
    assert_includes response.body, "TOOLS.md"
    assert_includes response.body, "AGENTS.md"
    assert_includes response.body, "presa.token"
  end

  test "GET /bots/client/presa returns the client script with base URL baked in" do
    get bots_client_path

    assert_response :success
    assert_includes response.content_type, "text/x-sh"
    assert_includes response.body, "BASE_URL=\"#{@base_url}\""
    assert_includes response.body, "/bots/tools/$t/execute"
    assert_includes response.body, "presa.token"
  end

  test "GET /bots/client/install.sh embeds the client and is executable-shaped" do
    get bots_client_installer_path

    assert_response :success
    assert_includes response.content_type, "text/x-sh"
    assert_includes response.body, "#--PRESA_CLIENT_BEGIN--"
    assert_includes response.body, "BASE_URL=\"#{@base_url}\""
    assert_includes response.body, "install."
  end

  test "GET /bots/tools lists the workspace's available tools as plain text" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    token = ApiToken.issue!(workspace: @workspace, name: "bot")

    get bots_tools_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_includes response.content_type, "text/plain"
    assert_includes response.body, "jellyfin_resume_items"
    refute_includes response.body, "jellyfin_get_episodes"
    refute_includes response.body, "Arguments:"
  end

  test "GET /bots/tools/:tool returns full detail for an allowed tool" do
    join = workspace_services(:one_github_prod)
    Current.workspace = @workspace
    name = ApplicationTool.expose_for(join.service).first.tool_name
    token = ApiToken.issue!(workspace: @workspace, name: "bot")

    get bots_tool_path(name), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_includes response.body, name
    assert_includes response.body, "Arguments:"
    assert_includes response.body, "q (string | required)"
  ensure
    Current.workspace = nil
  end

  test "GET /bots/tools/:tool is not found for a disallowed or unknown tool" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    token = ApiToken.issue!(workspace: @workspace, name: "bot")

    get bots_tool_path("jellyfin_get_episodes"), headers: { "Authorization" => "Bearer #{token}" }

    assert_response :not_found
  end

  test "GET /bots/tools/:tool requires a bearer token" do
    get bots_tool_path("github_list_issues")

    assert_response :unauthorized
  end

  test "GET /bots/workspace returns workspace name, services and tools" do
    join = workspace_services(:one_jellyfin)
    join.update!(allowed_tools: [ "resume_items" ])
    @workspace.update!(description: "A short blurb")
    token = ApiToken.issue!(workspace: @workspace, name: "bot")

    get bots_workspace_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_includes response.content_type, "text/plain"
    assert_includes response.body, "Workspace: #{@workspace.name}"
    assert_includes response.body, "Description: A short blurb"
    assert_includes response.body, "Services:"
    assert_match(/\(\w+\):\s*\d+ tool[s]?/, response.body) # each service: kind + tool count
    refute_includes response.body, "Tools:"
  end

  test "GET /bots/workspace requires a bearer token" do
    get bots_workspace_path

    assert_response :unauthorized
  end

  test "GET /bots/tools returns no tools for an empty workspace" do
    empty = Workspace.create!(name: "Empty", user: @user)
    token = ApiToken.issue!(workspace: empty, name: "bot")

    get bots_tools_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :success
    assert_equal "No tools available.\n", response.body
  end

  test "GET /bots/tools rejects a revoked or unknown token" do
    token = ApiToken.issue!(workspace: @workspace, name: "gone")
    ApiToken.find_active_by_token(token).revoke!

    get bots_tools_path, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unauthorized
  end

  test "POST /bots/tools/:tool/execute returns 404 for an unknown tool" do
    token = ApiToken.issue!(workspace: @workspace, name: "bot")

    post execute_bots_tool_path("bogus"), params: "{}",
         headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }

    assert_response :not_found
  end

  test "POST /bots/tools/:tool/execute requires a valid JSON body" do
    join = workspace_services(:one_github_prod)
    Current.workspace = @workspace
    name = ApplicationTool.expose_for(join.service).first.tool_name
    token = ApiToken.issue!(workspace: @workspace, name: "bot")

    post execute_bots_tool_path(name), params: "{not json",
         headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "text/plain" }

    assert_response :bad_request
  ensure
    Current.workspace = nil
  end
end
