# frozen_string_literal: true

require "test_helper"

class SpotifyGetArtistToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_artist"
  end

  test "fetches an artist by id" do
    tool = expose_spotify_tool("get_artist") do |stub|
      stub.get("/v1/artists/abc123") do |_env|
        spotify_json_response({ "id" => "abc123", "name" => "Radiohead" })
      end
    end

    result = tool.call(id: "abc123")
    assert_equal "Radiohead", result["name"]
  end
end
