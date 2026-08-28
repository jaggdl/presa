# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerSkipToNextToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "skip_to_next"
  end

  test "skips to the next track" do
    tool = expose_spotify_player_tool("skip_to_next") do |stub|
      stub.post("/v1/me/player/next") do |env|
        assert_nil env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call
  end

  test "targets a device" do
    tool = expose_spotify_player_tool("skip_to_next") do |stub|
      stub.post("/v1/me/player/next") do |env|
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(device_id: "dev123")
  end
end
