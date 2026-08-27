# frozen_string_literal: true

require "test_helper"

class SpotifyGetUserSavedTracksToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_user_saved_tracks"
  end

  test "fetches saved tracks with limit, offset, and market" do
    tool = expose_spotify_tool("get_user_saved_tracks") do |stub|
      stub.get("/v1/me/tracks") do |env|
        assert_equal "US", env.params["market"]
        assert_equal "10", env.params["limit"]
        assert_equal "0", env.params["offset"]
        spotify_json_response({ "items" => [], "total" => 42 })
      end
    end

    result = tool.call(limit: 10, offset: 0, market: "US")
    assert_equal 42, result["total"]
  end
end
