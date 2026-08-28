# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerSetPlaybackVolumeToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "set_playback_volume"
  end

  test "sets playback volume" do
    tool = expose_spotify_player_tool("set_playback_volume") do |stub|
      stub.put("/v1/me/player/volume") do |env|
        assert_equal "50", env.params["volume_percent"]
        assert_nil env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(volume_percent: 50)
  end

  test "targets a device" do
    tool = expose_spotify_player_tool("set_playback_volume") do |stub|
      stub.put("/v1/me/player/volume") do |env|
        assert_equal "80", env.params["volume_percent"]
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(volume_percent: 80, device_id: "dev123")
  end
end
