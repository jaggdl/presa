# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerToggleShuffleToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "toggle_shuffle"
  end

  test "toggles shuffle on" do
    tool = expose_spotify_player_tool("toggle_shuffle") do |stub|
      stub.put("/v1/me/player/shuffle") do |env|
        assert_equal "true", env.params["state"]
        assert_nil env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(state: true)
  end

  test "targets a device" do
    tool = expose_spotify_player_tool("toggle_shuffle") do |stub|
      stub.put("/v1/me/player/shuffle") do |env|
        assert_equal "false", env.params["state"]
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(state: false, device_id: "dev123")
  end
end
