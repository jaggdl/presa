# frozen_string_literal: true

require "test_helper"

class SpotifyGetUserSavedEpisodesToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_user_saved_episodes"
  end

  test "fetches saved episodes with limit, offset, and market" do
    tool = expose_spotify_tool("get_user_saved_episodes") do |stub|
      stub.get("/v1/me/episodes") do |env|
        assert_equal "10", env.params["limit"]
        assert_equal "0", env.params["offset"]
        assert_equal "US", env.params["market"]
        spotify_json_response({ "items" => [ { "episode" => { "name" => "Episode One" } } ], "total" => 1 })
      end
    end

    result = tool.call(limit: 10, offset: 0, market: "US")
    assert_equal "Episode One", result["items"].first["episode"]["name"]
  end
end
