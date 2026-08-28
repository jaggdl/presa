require "test_helper"

class OauthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @service = services(:gmail)
    @credential = oauth_client_credentials(:google_credential)
    sign_in_as @user
  end

  test "start redirects to the provider's consent screen for the user's own service and credential" do
    get oauth_start_path(service_id: @service.id, oauth_client_credential_id: @credential.id)

    assert_redirected_to %r{https://accounts.google.com/o/oauth2/v2/auth}
    url = URI(response.location)
    params = Rack::Utils.parse_nested_query(url.query)
    assert_equal "code", params["response_type"]
    assert_equal "google_client_1", params["client_id"]
    assert params["state"].present?
  end

  test "start redirects to services when the credential is not the user's own" do
    other = oauth_client_credentials(:google_credential)
    other.update!(team: teams(:two))

    get oauth_start_path(service_id: @service.id, oauth_client_credential_id: other.id)
    assert_redirected_to services_path
  end

  test "start requires authentication" do
    sign_out
    get oauth_start_path(service_id: @service, oauth_client_credential_id: @credential.id)
    assert_redirected_to new_session_path
  end

  test "callback exchanges the code and persists a grant on the service" do
    @service.oauth_grant.destroy!
    fake_exchange = Class.new do
      def exchange_code(token_uri:, code:, client_id:, client_secret:, redirect_uri:)
        { "access_token" => "exchanged_access", "refresh_token" => "exchanged_refresh", "expires_in" => 3600 }
      end
    end
    actual = Services::Gmail.method(:exchange_factory)
    Services::Gmail.define_singleton_method(:exchange_factory) { fake_exchange }

    state = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base).generate(
      { "service_id" => @service.id, "oauth_client_credential_id" => @credential.id },
      expires_in: 10.minutes,
      purpose: "oauth_start"
    )

    assert_difference -> { OauthGrant.count } do
      get oauth_callback_path, params: { code: "good_code", state: state }
    end

    Services::Gmail.define_singleton_method(:exchange_factory, &actual)

    assert_redirected_to service_path(@service)
    grant = @service.reload.oauth_grant
    assert_equal "exchanged_access", grant.access_token
    assert_equal @credential, grant.oauth_client_credential
  end

  test "callback rejects an invalid state" do
    assert_no_difference -> { OauthGrant.count } do
      get oauth_callback_path, params: { code: "good_code", state: "tampered" }
    end
    assert_redirected_to services_path
  end

  test "start redirects to the provider when creating a new service (kind and name only)" do
    get oauth_start_path(kind: "gmail", name: "My Gmail", oauth_client_credential_id: @credential.id)

    assert_redirected_to %r{https://accounts.google.com/o/oauth2/v2/auth}
    url = URI(response.location)
    params = Rack::Utils.parse_nested_query(url.query)
    assert_equal "google_client_1", params["client_id"]
    assert params["state"].present?
  end

  test "start rejects an unknown kind for the new-service flow" do
    get oauth_start_path(kind: "nope", name: "X", oauth_client_credential_id: @credential.id)
    assert_redirected_to services_path
  end

  test "callback creates a service and its grant from a kind-based state" do
    fake_exchange = Class.new do
      def exchange_code(token_uri:, code:, client_id:, client_secret:, redirect_uri:)
        { "access_token" => "new_service_access", "refresh_token" => "new_service_refresh", "expires_in" => 3600 }
      end
    end
    actual = Services::Gmail.method(:exchange_factory)
    Services::Gmail.define_singleton_method(:exchange_factory) { fake_exchange }

    state = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base).generate(
      { "kind" => "gmail", "name" => "My Gmail", "oauth_client_credential_id" => @credential.id },
      expires_in: 10.minutes,
      purpose: "oauth_start"
    )

    assert_difference -> { @user.services.count }, 1 do
      get oauth_callback_path, params: { code: "good_code", state: state }
    end

    Services::Gmail.define_singleton_method(:exchange_factory, &actual)

    service = @user.services.where(name: "My Gmail").first!
    assert_redirected_to service_path(service)
    assert_equal Services::Gmail, service.class
    assert_equal "new_service_access", service.oauth_grant.access_token
    assert_equal @credential, service.oauth_grant.oauth_client_credential
  end

  test "callback does not create a service when the code exchange fails" do
    fake_exchange = Class.new do
      def exchange_code(*)
        raise Oauth::Error, "invalid_grant"
      end
    end
    actual = Services::Gmail.method(:exchange_factory)
    Services::Gmail.define_singleton_method(:exchange_factory) { fake_exchange }

    state = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base).generate(
      { "kind" => "gmail", "name" => "My Gmail", "oauth_client_credential_id" => @credential.id },
      expires_in: 10.minutes,
      purpose: "oauth_start"
    )

    assert_no_difference -> { @user.services.count } do
      get oauth_callback_path, params: { code: "bad_code", state: state }
    end

    Services::Gmail.define_singleton_method(:exchange_factory, &actual)
    assert_redirected_to services_path
  end
end
