# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerSeekToPositionToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "seek_to_position"
  end

  test "seeks to a position" do
    tool = expose_spotify_player_tool("seek_to_position") do |stub|
      stub.put("/v1/me/player/seek") do |env|
        assert_equal "25000", env.params["position_ms"]
        assert_nil env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(position_ms: 25_000)
  end

  test "targets a device" do
    tool = expose_spotify_player_tool("seek_to_position") do |stub|
      stub.put("/v1/me/player/seek") do |env|
        assert_equal "25000", env.params["position_ms"]
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(position_ms: 25_000, device_id: "dev123")
  end
end
