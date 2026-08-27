# frozen_string_literal: true

require "test_helper"

class SpotifyGetRecentlyPlayedToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_recently_played"
  end

  test "fetches recently played with cursor params" do
    tool = expose_spotify_tool("get_recently_played") do |stub|
      stub.get("/v1/me/player/recently-played") do |env|
        assert_equal "1484811043508", env.params["after"]
        assert_equal "50", env.params["limit"]
        spotify_json_response({ "items" => [], "cursors" => { "after" => "1484811043723" } })
      end
    end

    result = tool.call(limit: 50, after: 1_484_811_043_508)
    assert_equal [], result["items"]
    assert_equal "1484811043723", result.dig("cursors", "after")
  end
end
