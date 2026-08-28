# frozen_string_literal: true

require "test_helper"

class SpotifyGetArtistRelatedArtistsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_artist_related_artists"
  end

  test "fetches an artist's related artists" do
    tool = expose_spotify_tool("get_artist_related_artists") do |stub|
      stub.get("/v1/artists/abc123/related-artists") do |_env|
        spotify_json_response({ "artists" => [ { "name" => "Pixies" } ] })
      end
    end

    result = tool.call(id: "abc123")
    assert_equal "Pixies", result["artists"].first["name"]
  end
end
