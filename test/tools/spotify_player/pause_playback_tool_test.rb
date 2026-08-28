# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerPausePlaybackToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "pause_playback"
  end

  test "pauses playback on the target device" do
    tool = expose_spotify_player_tool("pause_playback") do |stub|
      stub.put("/v1/me/player/pause") do |env|
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(device_id: "dev123")
  end

  test "pauses without a device" do
    tool = expose_spotify_player_tool("pause_playback") do |stub|
      stub.put("/v1/me/player/pause") do |env|
        assert_empty env.params
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call
  end
end
