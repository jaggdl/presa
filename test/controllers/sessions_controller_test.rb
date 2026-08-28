require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers
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

  test "account is locked after repeated failed attempts" do
    User::MAX_FAILED_LOGIN_ATTEMPTS.times do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
      assert_redirected_to new_session_path
      assert_nil cookies[:session_id]
    end

    @user.reload
    assert_equal User::MAX_FAILED_LOGIN_ATTEMPTS, @user.failed_login_attempts
    assert @user.locked_out?

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "successful sign-in resets the failed attempt counter" do
    3.times { post session_path, params: { email_address: @user.email_address, password: "wrong" } }
    assert_equal 3, @user.reload.failed_login_attempts

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_path
    assert_equal 0, @user.reload.failed_login_attempts
  end

  test "fixed failed attempts below the threshold do not lock the account" do
    (User::MAX_FAILED_LOGIN_ATTEMPTS - 1).times do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
    end

    @user.reload
    assert_not @user.locked_out?

    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "failed attempts against an unknown email are recorded nowhere" do
    post session_path, params: { email_address: "ghost@example.com", password: "wrong" }
    assert_redirected_to new_session_path

    assert_equal 0, User.where(email_address: "ghost@example.com").count
  end

  test "expired session is destroyed and requires reauthentication" do
    sign_in_as(@user)
    @user.sessions.update_all(expires_at: 1.minute.ago)

    travel_to(2.minutes.from_now) do
      get root_path
      assert_redirected_to new_session_path
      assert_empty @user.sessions.reload
      assert_empty cookies[:session_id]
    end
  end

  test "session expiry slides forward with activity" do
    sign_in_as(@user)
    @user.sessions.update_all(expires_at: 10.minutes.from_now)

    get root_path
    assert_response :success

    assert_in_delta Session::SLIDING_IDLE_TIMEOUT.from_now.to_i, @user.sessions.reload.first.expires_at.to_i, 10
  end

  test "old sessions are rotated to a fresh id" do
    sign_in_as(@user)
    old_id = cookies[:session_id]
    @user.sessions.update_all(created_at: Session::ROTATE_AFTER.ago - 1.minute)

    get root_path
    assert_response :success
    assert_equal 1, @user.sessions.reload.count
    assert_not_equal old_id, cookies[:session_id]
  end

  test "recently-created sessions are not rotated" do
    sign_in_as(@user)
    old_id = cookies[:session_id]

    get root_path
    assert_response :success
    assert_equal 1, @user.sessions.reload.count
    assert_equal old_id, cookies[:session_id]
  end

  test "lockout expires and a correct password signs in afterwards" do
    User::MAX_FAILED_LOGIN_ATTEMPTS.times do
      post session_path, params: { email_address: @user.email_address, password: "wrong" }
    end
    @user.reload
    assert @user.locked_out?

    travel_to(User::LOCKOUT_DURATION.from_now + 1.minute) do
      post session_path, params: { email_address: @user.email_address, password: "password" }
      assert_redirected_to root_path
      assert cookies[:session_id]
      assert_equal 0, @user.reload.failed_login_attempts
    end
  end
end
