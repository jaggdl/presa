# frozen_string_literal: true

require "test_helper"

class SpotifyGetPlaylistItemsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_playlist_items"
  end

  test "fetches a playlist's items with paging params" do
    tool = expose_spotify_tool("get_playlist_items") do |stub|
      stub.get("/v1/playlists/PL-1/items") do |env|
        assert_equal "5", env.params["limit"]
        assert_equal "10", env.params["offset"]
        assert_equal "items(added_at)", env.params["fields"]
        spotify_json_response({ "items" => [ { "track" => { "name" => "Midnight" } } ], "total" => 1 })
      end
    end

    result = tool.call(playlist_id: "PL-1", limit: 5, offset: 10, fields: "items(added_at)")
    assert_equal "Midnight", result["items"].first["track"]["name"]
  end
end
