# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerGetUserQueueToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "get_user_queue"
  end

  test "fetches the user's queue" do
    tool = expose_spotify_player_tool("get_user_queue") do |stub|
      stub.get("/v1/me/player/queue") do
        [ 200, { "content-type" => "application/json" }, JSON.generate({ "queue" => [] }) ]
      end
    end

    result = tool.call
    assert_equal [], result["queue"]
  end
end
