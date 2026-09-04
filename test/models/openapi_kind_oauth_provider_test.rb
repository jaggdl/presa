# frozen_string_literal: true

require "test_helper"

class OpenapiKindOauthProviderTest < ActiveSupport::TestCase
  setup do
    @team = teams(:one)
  end

  def oauth_definition
    {
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
  end

  test "defaults to the namespace when the spec declares an OAuth flow" do
    kind = OpenapiKind.create!(team: @team, title: "t", namespace: "youtube_analytics",
                               category: "general", definition: oauth_definition)
    assert_nil kind.read_attribute(:oauth_provider)
    assert_equal "youtube_analytics", kind.oauth_provider
  end

  test "a stored override wins over the namespace" do
    kind = OpenapiKind.create!(team: @team, title: "t", namespace: "youtube_analytics",
                               oauth_provider: "google", category: "general",
                               definition: oauth_definition)
    assert_equal "google", kind.oauth_provider
    assert_equal Oauth::Google, Oauth::Base.for_provider(kind.oauth_provider)
  end

  test "an override stored on a kind without an OAuth flow stays nil" do
    kind = OpenapiKind.create!(team: @team, title: "t", namespace: "youtube_analytics",
                               oauth_provider: "google", category: "general",
                               definition: { "operations" => [], "operation_count" => 0, "tag_count" => 0 })
    assert_nil kind.oauth_provider
  end
end