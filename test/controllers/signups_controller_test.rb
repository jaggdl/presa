require "test_helper"

class SignupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @default_multi_tenant = Team.multi_tenant
  end

  teardown do
    Team.multi_tenant = @default_multi_tenant
  end

  test "first run shows the first-run form and creates the first user with a team" do
    Team.multi_tenant = false
    User.destroy_all

    get new_signup_path
    assert_response :success
    assert_select "h1", text: "Welcome to Presa"

    assert_difference [ -> { User.count }, -> { Team.count }, -> { TeamMembership.count } ], 1 do
      post signup_path, params: {
        signup: { email_address: "solo@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    user = User.find_by!(email_address: "solo@example.com")
    assert_equal 1, user.teams.count
    assert_redirected_to root_url
  end

  test "first run creates a working session after signup" do
    Team.multi_tenant = false
    User.destroy_all

    post signup_path, params: {
      signup: { email_address: "solo@example.com", password: "password123", password_confirmation: "password123" }
    }

    assert cookies[:session_id]
    follow_redirect!
    assert_response :success
  end

  test "signup is closed once users exist in single-tenant mode" do
    Team.multi_tenant = false

    assert_not Team.first_run?
    get new_signup_path
    assert_redirected_to new_session_path

    assert_no_difference -> { User.count } do
      post signup_path, params: {
        signup: { email_address: "extra@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_redirected_to new_session_path
  end

  test "multi-tenant mode allows additional signups" do
    Team.multi_tenant = true

    get new_signup_path
    assert_response :success
    assert_select "h1", text: "Create your account"

    assert_difference [ -> { User.count }, -> { Team.count } ], 1 do
      post signup_path, params: {
        signup: { email_address: "second@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_redirected_to root_url
  end

  test "signed-in users are redirected away from signup" do
    sign_in_as users(:one)

    get new_signup_path
    assert_redirected_to root_path
  end

  test "invalid signup rerenders the form with errors" do
    Team.multi_tenant = false
    User.destroy_all

    assert_no_difference -> { User.count } do
      post signup_path, params: {
        signup: { email_address: "solo@example.com", password: "short", password_confirmation: "nomatch" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", text: "Welcome to Presa"
    assert_select "li", /too short/i
    assert_select "li", /confirmation doesn't match/i
  end
end
