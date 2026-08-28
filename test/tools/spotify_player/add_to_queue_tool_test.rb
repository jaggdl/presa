# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerAddToQueueToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "add_to_queue"
  end

  test "adds an item to the queue" do
    tool = expose_spotify_player_tool("add_to_queue") do |stub|
      stub.post("/v1/me/player/queue") do |env|
        assert_equal "spotify:track:abc", env.params["uri"]
        assert_nil env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(uri: "spotify:track:abc")
  end

  test "targets a device" do
    tool = expose_spotify_player_tool("add_to_queue") do |stub|
      stub.post("/v1/me/player/queue") do |env|
        assert_equal "spotify:track:abc", env.params["uri"]
        assert_equal "dev123", env.params["device_id"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(uri: "spotify:track:abc", device_id: "dev123")
  end
end
