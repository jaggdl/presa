# frozen_string_literal: true

require "test_helper"

class SpotifyGetUserSavedShowsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_user_saved_shows"
  end

  test "fetches saved shows with paging params" do
    tool = expose_spotify_tool("get_user_saved_shows") do |stub|
      stub.get("/v1/me/shows") do |env|
        assert_equal "5", env.params["limit"]
        assert_equal "10", env.params["offset"]
        spotify_json_response({ "items" => [ { "show" => { "name" => "The Daily" } } ], "total" => 1 })
      end
    end

    result = tool.call(limit: 5, offset: 10)
    assert_equal "The Daily", result["items"].first["show"]["name"]
  end
end
