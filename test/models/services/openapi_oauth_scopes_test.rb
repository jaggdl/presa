# frozen_string_literal: true

require "test_helper"

class OpenapiOAuthScopesTest < ActiveSupport::TestCase
  setup do
    @team = teams(:one)
    @kind = OpenapiKind.create!(
      team: @team, title: "YouTube Analytics", namespace: "youtube_analytics",
      oauth_provider: "google", category: "productivity",
      definition: {
        "operations" => [], "operation_count" => 0, "tag_count" => 0,
        "security" => {
          "Oauth2c" => {
            "kind" => "oauth",
            "authorization_url" => "https://accounts.google.com/o/oauth2/auth",
            "token_url" => "https://accounts.google.com/o/oauth2/token",
            "scopes" => { "https://www.googleapis.com/auth/yt-analytics.readonly" => "View reports" }
          }
        }
      }
    )
    @service = Services::Openapi.new(team: @team, name: "YT Analytics", openapi_kind: @kind)
  end

  test "falls back to the grant's granted scopes when the client configures none" do
    credential = oauth_client_credentials(:google_credential) # fixture has no scope
    @service.build_oauth_grant(
      oauth_client_credential: credential, provider: "google",
      access_token: "tok", token_type: "Bearer",
      scope: "https://www.googleapis.com/auth/yt-analytics.readonly https://www.googleapis.com/auth/youtube.readonly"
    )
    @service.save!

    assert_equal [ "https://www.googleapis.com/auth/yt-analytics.readonly",
                   "https://www.googleapis.com/auth/youtube.readonly" ],
                 @service.configured_oauth_scopes
  end

  test "the client credential's configured scope wins over the grant's" do
    credential = oauth_client_credentials(:google_credential)
    credential.update!(scope: "https://www.googleapis.com/auth/yt-analytics.readonly")
    @service.build_oauth_grant(
      oauth_client_credential: credential, provider: "google",
      access_token: "tok", token_type: "Bearer",
      scope: "https://www.googleapis.com/auth/youtube.readonly"
    )
    @service.save!

    assert_equal [ "https://www.googleapis.com/auth/yt-analytics.readonly" ],
                 @service.configured_oauth_scopes
  end

  test "empty without a grant" do
    @service.save!
    assert_empty @service.configured_oauth_scopes
  end

  test "authorize_url requests the kind's scope for a persisted (base-class) instance" do
    credential = oauth_client_credentials(:google_credential)
    @service.build_oauth_grant(
      oauth_client_credential: credential, provider: "google",
      access_token: "tok", token_type: "Bearer"
    )
    @service.save!

    url = @service.authorize_url(redirect_uri: "https://presa.example/oauth/callback", state: "st")
    params = Rack::Utils.parse_nested_query(URI(url).query)

    assert_equal "https://www.googleapis.com/auth/yt-analytics.readonly", params["scope"]
    assert_equal "offline", params["access_type"]
    assert_equal "consent", params["prompt"]
  end
end
