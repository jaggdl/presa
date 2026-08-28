# frozen_string_literal: true

require "test_helper"

class Services::SpotifyTest < ActiveSupport::TestCase
  Oauth::Exchange # autoload Oauth::Error

  test "is an offerable Spotify OAuth leaf" do
    assert_equal "spotify", Services::Spotify.kind
    assert_includes Service.kinds, "spotify"
    assert_equal "spotify", Services::Spotify.oauth_provider.to_s
    assert_equal "https://accounts.spotify.com/authorize", Services::Spotify.provider_class.authorize_uri
    assert_equal "https://accounts.spotify.com/api/token", Services::Spotify.provider_class.token_uri
    assert_equal Oauth::Spotify, Services::Spotify.provider_class
  end

  test "is categorized as media" do
    assert_equal "media", Services::Spotify.category
    assert_equal "spotify.png", Services::Spotify.icon
  end

  test "requests only the minimum scope for its features" do
    scope = Services::Spotify.oauth_scope
    assert_includes scope, "user-read-private"
    assert_includes scope, "user-top-read"
    assert_includes scope, "user-read-recently-played"
    assert_includes scope, "user-library-read"
    assert_includes scope, "playlist-read-private"
    assert_not_includes scope, "user-modify-playback-state"
  end

  test "is valid as an OAuth service" do
    assert services(:spotify).valid?
  end

  test "builds an authorize url with the client and redirect target" do
    service = Services::Spotify.new(name: "Spotify")
    client = OauthClientCredential.new(client_id: "spotify_client_1")

    url = Services::Spotify.authorize_url_for(client: client, redirect_uri: "https://presa.example/oauth/callback", state: "abc123")
    assert_includes url, "https://accounts.spotify.com/authorize"
    assert_includes url, "client_id=spotify_client_1"
    assert_includes url, "redirect_uri=https%3A%2F%2Fpresa.example%2Foauth%2Fcallback"
    assert_includes url, "state=abc123"
    assert_includes url, "scope="
    assert_includes url, "user-read-private"
  end
end
