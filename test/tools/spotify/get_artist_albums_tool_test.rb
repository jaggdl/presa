# frozen_string_literal: true

require "test_helper"

class SpotifyGetArtistAlbumsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_artist_albums"
  end

  test "fetches an artist's albums with filters" do
    tool = expose_spotify_tool("get_artist_albums") do |stub|
      stub.get("/v1/artists/abc123/albums") do |env|
        assert_equal "album,single", env.params["include_groups"]
        assert_equal "10", env.params["limit"]
        assert_equal "5", env.params["offset"]
        assert_equal "US", env.params["market"]
        spotify_json_response({ "items" => [ { "name" => "OK Computer" } ] })
      end
    end

    result = tool.call(id: "abc123", include_groups: [ "album", "single" ], limit: 10, offset: 5, market: "US")
    assert_equal "OK Computer", result["items"].first["name"]
  end

  test "fetches an artist's albums without optional params" do
    tool = expose_spotify_tool("get_artist_albums") do |stub|
      stub.get("/v1/artists/abc123/albums") do |env|
        assert_nil env.params["include_groups"]
        assert_nil env.params["limit"]
        spotify_json_response({ "items" => [] })
      end
    end

    tool.call(id: "abc123")
  end
end
