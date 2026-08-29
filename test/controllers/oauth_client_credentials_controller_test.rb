require "test_helper"

class OauthClientCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "new renders the form" do
    get new_oauth_client_credential_path(provider: "google")
    assert_response :success
    assert_select "input[type=hidden][name='oauth_client_credential[provider]'][value=google]"
  end

  test "new shows the callback redirect URI with a copy button" do
    get new_oauth_client_credential_path(provider: "google")
    assert_select "pre", text: oauth_callback_url
    assert_select "button[data-action='click->copy#copy'][aria-label='Copy to clipboard'] svg"
  end

  test "index shows provider tiles for every OAuth provider" do
    get oauth_client_credentials_path
    assert_response :success
    assert_select "a[href='/oauth_client_credentials/new?provider=google']"
    assert_select "a[href='/oauth_client_credentials/new?provider=strava']"
    assert_select "span", text: "Google"
    assert_select "span", text: "Strava"
  end

  test "index lists the user's credentials" do
    get oauth_client_credentials_path
    assert_response :success
    assert_select "td span", text: "Prod Google app"
    assert_select "div", text: "google"
  end

  test "create saves a client credential with a name for the current user" do
    assert_difference -> { @user.oauth_client_credentials.count }, 1 do
      post oauth_client_credentials_path, params: {
        oauth_client_credential: {
          provider: "google",
          name: "Prod app",
          client_id: "client_abc",
          client_secret: "secret_abc"
        }
      }
    end
    assert_redirected_to oauth_client_credentials_path
    assert_equal "client_abc", @user.oauth_client_credentials.last.client_id
    assert_equal "Prod app", @user.oauth_client_credentials.last.name
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
    cred = @user.teams.first.oauth_client_credentials.create!(provider: "google", name: "X", client_id: "c", client_secret: "s")
    assert_difference -> { @user.oauth_client_credentials.count }, -1 do
      delete oauth_client_credential_path(cred)
    end
    assert_redirected_to oauth_client_credentials_path
  end

  test "edit renders the form with the stored name and client id" do
    cred = oauth_client_credentials(:google_credential)
    get edit_oauth_client_credential_path(cred)
    assert_response :success
    assert_select "h1", text: "Edit OAuth client"
    assert_select "input[name='oauth_client_credential[name]'][value='Prod Google app']"
    assert_select "input[name='oauth_client_credential[client_id]'][value='google_client_1']"
  end

  test "update changes editable fields and honours return_to" do
    cred = oauth_client_credentials(:google_credential)
    patch oauth_client_credential_path(cred), params: {
      oauth_client_credential: { name: "Renamed", client_id: "new_cid" },
      return_to: "/services/1"
    }
    assert_redirected_to "/services/1"
    cred.reload
    assert_equal "Renamed", cred.name
    assert_equal "new_cid", cred.client_id
  end

  test "update keeps the stored secret when the secret field is blank" do
    cred = oauth_client_credentials(:google_credential)
    patch oauth_client_credential_path(cred), params: {
      oauth_client_credential: { name: "Renamed", client_secret: "" }
    }
    assert_redirected_to oauth_client_credentials_path
    cred.reload
    assert_equal "Renamed", cred.name
    assert_equal "secret_google_1", cred.client_secret
  end

  test "update renders errors on invalid input" do
    cred = oauth_client_credentials(:google_credential)
    patch oauth_client_credential_path(cred), params: {
      oauth_client_credential: { name: "", client_id: "" }
    }
    assert_response :unprocessable_entity
  end

  test "modal create streams the new credential into the selector" do
    assert_difference -> { @user.oauth_client_credentials.count }, 1 do
      post oauth_client_credentials_path, params: {
        modal: "1",
        oauth_client_credential: { provider: "google", name: "New app", client_id: "cid_modal", client_secret: "secret_modal" }
      }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type

    created = @user.oauth_client_credentials.order(:id).last
    assert_match %r{turbo-stream action="remove"}, response.body
    assert_match %r{turbo-stream action="replace"}, response.body
    assert_includes response.body, created.id.to_s
    assert_includes response.body, "New app"
  end

  test "modal create re-renders the form with errors on invalid input" do
    post oauth_client_credentials_path, params: {
      modal: "1",
      oauth_client_credential: { provider: "google", name: "", client_id: "", client_secret: "" }
    }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match %r{turbo-stream action="update"}, response.body
    assert_match "Name can&#39;t be blank", response.body
  end
end
