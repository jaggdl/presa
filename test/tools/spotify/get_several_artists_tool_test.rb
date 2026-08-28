# frozen_string_literal: true

require "test_helper"

class SpotifyGetSeveralArtistsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_several_artists"
  end

  test "fetches several artists with comma-joined ids" do
    tool = expose_spotify_tool("get_several_artists") do |stub|
      stub.get("/v1/artists") do |env|
        assert_equal "abc,def", env.params["ids"]
        spotify_json_response({ "artists" => [ { "name" => "A" }, { "name" => "B" } ] })
      end
    end

    result = tool.call(ids: [ "abc", "def" ])
    assert_equal "A", result["artists"][0]["name"]
  end
end
