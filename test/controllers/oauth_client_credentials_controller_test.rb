require "test_helper"

class OauthClientCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "new renders the form" do
    get new_oauth_client_credential_path(provider: "google")
    assert_response :success
  end

  test "create saves a client credential for the current user" do
    assert_difference -> { @user.oauth_client_credentials.count }, 1 do
      post oauth_client_credentials_path, params: {
        oauth_client_credential: {
          provider: "google",
          client_id: "client_abc",
          client_secret: "secret_abc"
        }
      }
    end
    assert_redirected_to services_path
    assert_equal "client_abc", @user.oauth_client_credentials.last.client_id
  end

  test "create renders errors on invalid input" do
    assert_no_difference -> { @user.oauth_client_credentials.count } do
      post oauth_client_credentials_path, params: {
        oauth_client_credential: { provider: "google", client_id: "", client_secret: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "destroy removes a client credential" do
    cred = @user.oauth_client_credentials.create!(provider: "google", client_id: "c", client_secret: "s")
    assert_difference -> { @user.oauth_client_credentials.count }, -1 do
      delete oauth_client_credential_path(cred)
    end
    assert_redirected_to services_path
  end
end
