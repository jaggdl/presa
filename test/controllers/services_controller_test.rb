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

  test "show lists the service's available tools" do
    get service_path(services(:github_prod))
    assert_response :success
    assert_select "h2", text: "Tools"
    assert_select "code", text: "list_issues_github_prod"
    assert_select "code", text: "repo"
  end

  test "show renders no-argument tools without error" do
    get service_path(services(:jellyfin))
    assert_response :success
    assert_select "code", text: "get_system_info_jellyfin_jellyfin"
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
end
