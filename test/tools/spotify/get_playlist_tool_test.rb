# frozen_string_literal: true

require "test_helper"

class SpotifyGetPlaylistToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_playlist"
  end

  test "fetches a playlist with fields and market" do
    tool = expose_spotify_tool("get_playlist") do |stub|
      stub.get("/v1/playlists/PL-1") do |env|
        assert_equal "items(name,id)", env.params["fields"]
        assert_equal "US", env.params["market"]
        spotify_json_response({ "id" => "PL-1", "name" => "Focus" })
      end
    end

    result = tool.call(playlist_id: "PL-1", fields: "items(name,id)", market: "US")
    assert_equal "Focus", result["name"]
  end
end
