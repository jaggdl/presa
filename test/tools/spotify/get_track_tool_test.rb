# frozen_string_literal: true

require "test_helper"

class SpotifyGetTrackToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_track"
  end

  test "fetches a track by id" do
    tool = expose_spotify_tool("get_track") do |stub|
      stub.get("/v1/tracks/abc123") do |env|
        assert_nil env.params["market"]
        spotify_json_response({ "id" => "abc123", "name" => "Lucky" })
      end
    end

    result = tool.call(id: "abc123")
    assert_equal "Lucky", result["name"]
  end

  test "passes market as a query param" do
    tool = expose_spotify_tool("get_track") do |stub|
      stub.get("/v1/tracks/abc123") do |env|
        assert_equal "US", env.params["market"]
        spotify_json_response({ "id" => "abc123" })
      end
    end

    tool.call(id: "abc123", market: "US")
  end
end
