# frozen_string_literal: true

require "test_helper"

class Services::OpenapiTest < ActiveSupport::TestCase
  def definition
    raw, root = Openapi::Parser.parse(source: "raw", input: File.read(Rails.root.join("test/support/openapi/widget_api.yml")))
    Openapi::Generator.generate(root)
  end

  def build_service(extra = {})
    Services::Openapi.new(
      team: teams(:one),
      name: "Widgets",
      config: { namespace: "widgets", title: "Widgets", base_url: "https://api.example.com/v2", spec: definition }.merge(extra)
    )
  end

  test "exposes a per-instance kind derived from the namespace" do
    service = build_service

    assert_equal "widgets", service.kind
    assert_equal "Widgets", service.display_name
  end

  test "is not offered as a static picker card" do
    refute Service.offerable?(Services::Openapi)
    refute_includes Service.kinds, "openapi"
  end

  test "derives credential config fields from security schemes" do
    service = build_service
    schema = service.config_schema

    assert schema.key?("cred_api_key_auth")
    assert schema.key?("cred_bearer_auth")
    assert schema.key?("cred_cookie_auth")
    assert schema.key?("cred_basic_auth")
    assert schema.values.all? { |opts| opts["secret"] }
  end

  test "requires a spec in config" do
    service = Services::Openapi.new(team: teams(:one), name: "Empty", config: { namespace: "empty" })

    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("spec") }
  end

  test "validates base URL is http(s)" do
    service = build_service("base_url" => "ftp://nope")

    assert_not service.valid?
    assert service.errors[:config].any? { |e| e.to_s.include?("http") }
  end

  test "generates one tool descriptor per operation, namespaced" do
    service = build_service
    tools = service.openapi_tools

    assert_equal 4, tools.size
    names = tools.map { |t| t["name"] }
    assert_includes names, "widgets_get_widget_by_id"
    assert_includes names, "widgets_create_widget"
  end

  test "tool names drop a namespace-shaped lead-in from the operation slug" do
    gmail = build_service(namespace: "gmail")
    assert_equal "gmail_users_get_profile", gmail.tool_name_for("gmail_users_get_profile")
    assert_equal "gmail_users_get_profile", gmail.tool_name_for("users_get_profile")
    # A similar-looking but unrelated lead-in is kept.
    assert_equal "gmail_gmailbox_print", gmail.tool_name_for("gmailbox_print")

    ytr = build_service(namespace: "youtube_reporting")
    assert_equal "youtube_reporting_jobs_list", ytr.tool_name_for("youtubereporting_jobs_list")
    assert_equal "youtube_reporting_jobs_list", ytr.tool_name_for("youtube_reporting_jobs_list")
    assert_equal "youtube_reporting_jobs_list", ytr.tool_name_for("jobs_list")
  end

  test "expose_for resolves the deduped tool name back to its operation" do
    service = build_service(namespace: "gmail")
    service.save!
    ops = [
      { "method" => "GET", "path" => "/users/me/profile", "operation_id" => "gmail.users.getProfile",
        "name" => "gmail_users_get_profile", "summary" => "", "description" => "",
        "tags" => [], "security" => {}, "security_requirements" => [], "args_schema" => { "type" => "object", "properties" => {} } }
    ]
    service.define_singleton_method(:operations) { ops }
    classes = ApplicationTool.expose_for(service)

    assert_equal 1, classes.size
    tool = classes.first
    assert_equal "gmail_users_get_profile", tool.tool_name
    assert_equal "gmail_users_get_profile", tool.remote_tool_name
    assert_equal ops.first, tool.remote_openapi_operation
  end

  test "expose_for builds bound openapi tool classes" do
    service = build_service
    service.save!
    classes = ApplicationTool.expose_for(service)

    assert_equal 4, classes.size
    names = classes.map(&:tool_name)
    assert_includes names, "widgets_create_widget"
    tool = classes.find { |t| t.tool_name == "widgets_create_widget" }
    assert_equal service.id, tool.service_id
    assert_equal service.operations.find { |o| o["operation_id"] == "createWidget" }, tool.remote_openapi_operation
  end

  test "tool input_schema_to_json surfaces the operation args schema" do
    service = build_service
    tool = ApplicationTool.expose_for(service).find { |t| t.tool_name == "widgets_get_widget_by_id" }

    schema = tool.input_schema_to_json
    assert schema["properties"].key?("id")
    assert_equal [ "id" ], schema["required"]
  end

  test "auth: applies bearer, api key, and cookie schemes from credentials" do
    service = build_service("cred_bearer_auth" => "beartok", "cred_api_key_auth" => "key123")

    op = service.operations.find { |o| o["operation_id"] == "getWidgetById" }
    query, headers, cookies = {}, {}, {}
    service.send(:apply_auth, op, query, headers, cookies)

    assert_equal "Bearer beartok", headers["Authorization"]
    assert_equal "key123", headers["X-API-Key"]
    refute cookies.key?("wsid")
  end

  test "auth: first present credential wins when schemes chain" do
    service = build_service("cred_bearer_auth" => "beartok")

    op = service.operations.find { |o| o["operation_id"] == "getWidgetById" }
    query, headers, cookies = {}, {}, {}
    service.send(:apply_auth, op, query, headers, cookies)

    assert_equal "Bearer beartok", headers["Authorization"]
    # Only the first present credential applies; the API key stays unset.
    refute headers.key?("X-API-Key")
  end

  test "rebuilds path params, query, headers, and JSON body when executing" do
    service = build_service("cred_bearer_auth" => "tok")
    captured = {}
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/v2/widgets/w1") do |env|
      captured[:env] = env
      [ 200, { "content-type" => "application/json" }, JSON.generate(id: "w1") ]
    end
    service.instance_variable_set(:@client, faraday_conn(stubs))

    op = service.operations.find { |o| o["operation_id"] == "getWidgetById" }
    result = service.execute_operation(op, "id" => "w1", "verbose" => true, "X-Request-Id" => "req-1")

    assert_equal({ "id" => "w1" }, result)
    env = captured[:env]
    assert_equal "https://api.example.com/v2/widgets/w1", env[:url].to_s.sub(/\?.*/, "")
    assert_equal "true", env.params["verbose"]
    assert_equal "req-1", env.request_headers["X-Request-Id"]
    assert_equal "Bearer tok", env.request_headers["Authorization"]
  end

  test "builds a JSON request body from flattened body args" do
    service = build_service("cred_cookie_auth" => "sess")
    captured = {}
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.post("/v2/widgets") do |env|
      captured[:body] = env.body
      captured[:headers] = env.request_headers
      [ 201, { "content-type" => "application/json" }, JSON.generate(id: "w9") ]
    end
    service.instance_variable_set(:@client, faraday_conn(stubs))

    op = service.operations.find { |o| o["operation_id"] == "createWidget" }
    result = service.execute_operation(op, "name" => "Gadget", "tags" => [ "a", "b" ])

    assert_equal({ "id" => "w9" }, result)
    assert_equal "sess", captured[:headers]["Cookie"].to_s[/wsid=(\w+)/, 1]
    assert_equal "application/json", captured[:headers]["Content-Type"]
    body = JSON.parse(captured[:body])
    assert_equal "Gadget", body["name"]
    assert_equal %w[a b], body["tags"]
  end

  test "returns an error payload for non-2xx responses" do
    service = build_service("cred_bearer_auth" => "tok")
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/v2/widgets/w1") { |_| [ 401, { "content-type" => "application/json" }, JSON.generate(message: "Unauthorized") ] }
    service.instance_variable_set(:@client, faraday_conn(stubs))

    op = service.operations.find { |o| o["operation_id"] == "getWidgetById" }
    result = service.execute_operation(op, "id" => "w1")

    assert_kind_of Hash, result
    assert_match(/401/, result["error"].to_s)
  end

  test "raises when a required path parameter is missing" do
    service = build_service("cred_bearer_auth" => "tok")
    service.instance_variable_set(:@client, faraday_conn(Faraday::Adapter::Test::Stubs.new))

    op = service.operations.find { |o| o["operation_id"] == "getWidgetById" }
    assert_raises(ArgumentError) { service.execute_operation(op, {}) }
  end

  test "health check extracts an identity label from the response" do
    service = build_service("cred_bearer_auth" => "tok")
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/v2/health") { |_| [ 200, { "content-type" => "application/json" }, JSON.generate(status: "ok", owner: { email: "ada@example.com" }) ] }
    service.instance_variable_set(:@client, faraday_conn(stubs))

    service.test_connection("health_op" => "healthCheck", "health_identity" => "owner.email")

    assert_equal "ada@example.com", service.health_label
  end

  test "health check only (no identity) succeeds with 2xx" do
    service = build_service("cred_bearer_auth" => "tok")
    service.config[:base_url] = "https://api.example.com/v2"
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/v2/health") { |_| [ 200, { "content-type" => "application/json" }, JSON.generate(status: "ok") ] }
    service.instance_variable_set(:@client, faraday_conn(stubs))

    assert service.test_connection("health_op" => "healthCheck")

    assert_nil service.health_label
  end

  test "test_connection validates required credentials when no health op" do
    service = build_service

    assert_raises(RuntimeError) { service.test_connection({}) }
  end

  private

  def faraday_conn(stubs)
    Faraday.new(url: "https://api.example.com") do |f|
      f.response :json, content_type: /\bjson$/
      f.adapter :test, stubs
    end
  end
end