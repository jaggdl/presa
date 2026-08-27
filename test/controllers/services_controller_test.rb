require "test_helper"

class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "index requires authentication" do
    sign_out
    get services_path
    assert_redirected_to new_session_path
  end

  test "index lists the user's services" do
    get services_path
    assert_response :success
    assert_select "a", text: "Prod"
  end

  test "index does not crash when a service's MCP endpoint is unreachable" do
    service = @user.services.create!(name: "Broken", type: "Services::Mcp",
                                     config: { url: "https://example.com/broken", headers: "{}" })
    service.define_singleton_method(:remote_tools) { |*| [] }

    get services_path
    assert_response :success
    assert_select "a", text: "Broken"
  end

  test "new renders the form" do
    get new_service_path
    assert_response :success
  end

  test "create builds the chosen service kind" do
    assert_difference -> { @user.services.count }, 1 do
      post services_path, params: { service: { name: "Staging2", kind: "github", config: { api_token: "tok", base_url: "https://api.github.com" } } }
    end

    assert_redirected_to services_path
    assert_equal Services::Github, @user.services.order(:id).last.class
  end

  test "create renders errors on invalid config" do
    assert_no_difference -> { @user.services.count } do
      post services_path, params: { service: { name: "Bad", kind: "github", config: { base_url: "https://x" } } }
    end

    assert_response :unprocessable_entity
  end

  test "show displays a service" do
    get service_path(services(:github_prod))
    assert_response :success
    assert_select "h1", text: "Prod"
  end

  test "show renders the service kind's markdown description" do
    get service_path(services(:github_prod))
    assert_response :success
    assert_select ".prose", text: /GitHub Copilot/
  end

  test "show lists the service's available tools" do
    get service_path(services(:jellyfin))
    assert_response :success
    assert_select "h2", text: "Tools"
    assert_select "code", text: "jellyfin_next_up"
    assert_select "code", text: "user_id"
  end

  test "show renders no-argument tools without error" do
    get service_path(services(:jellyfin))
    assert_response :success
    assert_select "code", text: "jellyfin_get_system_info"
    assert_select "p", text: "Accepts no arguments."
  end

  test "edit and update a service" do
    service = services(:github_prod)

    patch service_path(service), params: { service: { name: "Renamed", config: { api_token: "tok2", base_url: "https://api.github.com" } } }

    assert_redirected_to services_path
    assert_equal "Renamed", service.reload.name
  end

  test "destroy deletes a service" do
    service = @user.services.create!(name: "Temp", type: "Services::Github", config: { api_token: "tok" })

    assert_difference -> { @user.services.count }, -1 do
      delete service_path(service)
    end

    assert_redirected_to services_path
  end

  test "test_connection returns a turbo stream with a green indicator on success" do
    Services::Github.define_method(:test_connection) { |_config = nil| true }

    post test_connection_services_path, params: { service: { name: "G", kind: "github", config: { api_token: "tok" } } }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/text\/vnd\.turbo-stream/, response.content_type)
    assert_match /bg-green-400/, response.body
  ensure
    Services::Github.remove_method(:test_connection)
  end

  test "test_connection reports the error on failure" do
    Services::Github.define_method(:test_connection) { |_config = nil| raise "boom" }

    post test_connection_services_path, params: { service: { name: "G", kind: "github", config: { api_token: "tok" } } }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match /Connection failed: boom/, response.body
  ensure
    Services::Github.remove_method(:test_connection)
  end
end
