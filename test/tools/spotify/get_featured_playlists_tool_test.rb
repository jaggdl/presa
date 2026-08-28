# frozen_string_literal: true

require "test_helper"

class SpotifyGetFeaturedPlaylistsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_featured_playlists"
  end

  test "fetches featured playlists with query params" do
    tool = expose_spotify_tool("get_featured_playlists") do |stub|
      stub.get("/v1/browse/featured-playlists") do |env|
        assert_equal "es_MX", env.params["locale"]
        assert_equal "10", env.params["limit"]
        spotify_json_response({ "playlists" => { "items" => [] } })
      end
    end

    result = tool.call(locale: "es_MX", limit: 10)
    assert_equal [], result["playlists"]["items"]
  end
end
