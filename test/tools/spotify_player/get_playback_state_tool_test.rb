# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerGetPlaybackStateToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "get_playback_state"
  end

  test "fetches playback state" do
    tool = expose_spotify_player_tool("get_playback_state") do |stub|
      stub.get("/v1/me/player") do |env|
        assert_nil env.params["market"]
        [ 200, { "content-type" => "application/json" }, JSON.generate({ "is_playing" => true }) ]
      end
    end

    result = tool.call
    assert_equal true, result["is_playing"]
  end

  test "passes market and additional_types as query params" do
    tool = expose_spotify_player_tool("get_playback_state") do |stub|
      stub.get("/v1/me/player") do |env|
        assert_equal "US", env.params["market"]
        assert_equal "episode", env.params["additional_types"]
        [ 200, { "content-type" => "application/json" }, JSON.generate({}) ]
      end
    end

    tool.call(market: "US", additional_types: [ "episode" ])
  end
end
