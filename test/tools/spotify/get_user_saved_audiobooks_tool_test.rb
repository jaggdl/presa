# frozen_string_literal: true

require "test_helper"

class SpotifyGetUserSavedAudiobooksToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_user_saved_audiobooks"
  end

  test "fetches saved audiobooks with paging params" do
    tool = expose_spotify_tool("get_user_saved_audiobooks") do |stub|
      stub.get("/v1/me/audiobooks") do |env|
        assert_equal "5", env.params["limit"]
        assert_equal "10", env.params["offset"]
        spotify_json_response({ "items" => [ { "id" => "AB-1", "name" => "The Alchemist" } ], "total" => 1 })
      end
    end

    result = tool.call(limit: 5, offset: 10)
    assert_equal "The Alchemist", result["items"].first["name"]
  end
end
