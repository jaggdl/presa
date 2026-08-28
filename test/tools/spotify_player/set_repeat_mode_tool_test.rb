# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerSetRepeatModeToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "set_repeat_mode"
  end

  test "sets repeat mode" do
    tool = expose_spotify_player_tool("set_repeat_mode") do |stub|
      stub.put("/v1/me/player/repeat") do |env|
        assert_equal "context", env.params["state"]
        assert_nil env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(state: "context")
  end

  test "targets a device" do
    tool = expose_spotify_player_tool("set_repeat_mode") do |stub|
      stub.put("/v1/me/player/repeat") do |env|
        assert_equal "track", env.params["state"]
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(state: "track", device_id: "dev123")
  end
end
