# frozen_string_literal: true

require "test_helper"

class SpotifyGetUserPlaylistsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_user_playlists"
  end

  test "fetches the user's playlists with paging params" do
    tool = expose_spotify_tool("get_user_playlists") do |stub|
      stub.get("/v1/me/playlists") do |env|
        assert_equal "5", env.params["limit"]
        assert_equal "10", env.params["offset"]
        spotify_json_response({ "items" => [ { "name" => "Focus" } ], "total" => 1 })
      end
    end

    result = tool.call(limit: 5, offset: 10)
    assert_equal "Focus", result["items"].first["name"]
  end
end
