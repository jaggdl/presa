# frozen_string_literal: true

require "test_helper"

class SpotifyGetAlbumTracksToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_album_tracks"
  end

  test "fetches an album's tracks with paging params" do
    tool = expose_spotify_tool("get_album_tracks") do |stub|
      stub.get("/v1/albums/xyz789/tracks") do |env|
        assert_equal "10", env.params["limit"]
        assert_equal "5", env.params["offset"]
        assert_nil env.params["market"]
        spotify_json_response({ "items" => [ { "name" => "Come Together" } ], "total" => 17 })
      end
    end

    result = tool.call(id: "xyz789", limit: 10, offset: 5)
    assert_equal "Come Together", result["items"].first["name"]
  end

  test "passes market as a query param" do
    tool = expose_spotify_tool("get_album_tracks") do |stub|
      stub.get("/v1/albums/xyz789/tracks") do |env|
        assert_equal "US", env.params["market"]
        spotify_json_response({ "items" => [] })
      end
    end

    tool.call(id: "xyz789", market: "US")
  end
end
