# frozen_string_literal: true

require "test_helper"

class Services::SpotifyPlayerTest < ActiveSupport::TestCase
  Oauth::Exchange # autoload Oauth::Error

  test "is an offerable Spotify-backed OAuth leaf" do
    assert_equal "spotify_player", Services::SpotifyPlayer.kind
    assert_includes Service.kinds, "spotify_player"
    assert_equal "spotify", Services::SpotifyPlayer.oauth_provider.to_s
    assert_equal Oauth::Spotify, Services::SpotifyPlayer.provider_class
    assert_equal "https://api.spotify.com/v1", Services::SpotifyPlayer.oauth_api_base_url
  end

  test "composes a client against the API base URL" do
    assert_instance_of Oauth::Client, services(:spotify_player).client
  end

  test "is categorized as media with the Spotify icon" do
    assert_equal "media", Services::SpotifyPlayer.category
    assert_equal "spotify.png", Services::SpotifyPlayer.icon
  end

  test "requests only the minimum scope for its player features" do
    scope = Services::SpotifyPlayer.oauth_scope
    assert_includes scope, "user-read-playback-state"
    assert_includes scope, "user-read-currently-playing"
    assert_includes scope, "user-modify-playback-state"
    assert_not_includes scope, "user-library-read"
    assert_not_includes scope, "playlist-read-private"
  end

  test "is valid as an OAuth service" do
    assert services(:spotify_player).valid?
  end

  test "does not expose the base Spotify tools" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "pause_playback"
    assert_not_includes kinds, "get_track"
  end
end
