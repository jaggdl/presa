# frozen_string_literal: true

require "test_helper"

class SpotifyGetArtistTopTracksToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_artist_top_tracks"
  end

  test "fetches an artist's top tracks with a market" do
    tool = expose_spotify_tool("get_artist_top_tracks") do |stub|
      stub.get("/v1/artists/abc123/top-tracks") do |env|
        assert_equal "US", env.params["market"]
        spotify_json_response({ "tracks" => [ { "name" => "Creep" } ] })
      end
    end

    result = tool.call(id: "abc123", market: "US")
    assert_equal "Creep", result["tracks"].first["name"]
  end
end
