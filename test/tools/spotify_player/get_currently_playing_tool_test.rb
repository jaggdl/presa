# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerGetCurrentlyPlayingToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "get_currently_playing"
  end

  test "fetches currently playing item" do
    tool = expose_spotify_player_tool("get_currently_playing") do |stub|
      stub.get("/v1/me/player/currently-playing") do |env|
        assert_nil env.params["market"]
        [ 200, { "content-type" => "application/json" }, JSON.generate({ "is_playing" => false }) ]
      end
    end

    result = tool.call
    assert_equal false, result["is_playing"]
  end

  test "passes market and additional_types as query params" do
    tool = expose_spotify_player_tool("get_currently_playing") do |stub|
      stub.get("/v1/me/player/currently-playing") do |env|
        assert_equal "US", env.params["market"]
        assert_equal "episode,track", env.params["additional_types"]
        [ 200, { "content-type" => "application/json" }, JSON.generate({}) ]
      end
    end

    tool.call(market: "US", additional_types: %w[episode track])
  end
end
