require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create over https sets a secure session cookie" do
    post session_path, params: { email_address: @user.email_address, password: "password" },
      env: { "HTTPS" => "on" }

    assert_redirected_to root_path
    set_cookie = response.headers["Set-Cookie"].to_a.join("\n")
    assert_includes set_cookie, "session_id="
    assert_includes set_cookie, "secure"
  end

  test "create over plain http does not mark the session cookie secure" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    set_cookie = response.headers["Set-Cookie"].to_a.join("\n")
    session_cookie = set_cookie.lines.find { |line| line.include?("session_id=") }
    assert session_cookie
    assert_not_includes session_cookie.downcase, "secure"
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
