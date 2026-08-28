# frozen_string_literal: true

require "test_helper"

class SpotifyGetSeveralTracksToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_several_tracks"
  end

  test "fetches several tracks with comma-joined ids" do
    tool = expose_spotify_tool("get_several_tracks") do |stub|
      stub.get("/v1/tracks") do |env|
        assert_equal "abc,def", env.params["ids"]
        assert_nil env.params["market"]
        spotify_json_response({ "tracks" => [ { "id" => "abc" }, { "id" => "def" } ] })
      end
    end

    result = tool.call(ids: %w[abc def])
    assert_equal [ "abc", "def" ], result["tracks"].map { |t| t["id"] }
  end

  test "passes market as a query param" do
    tool = expose_spotify_tool("get_several_tracks") do |stub|
      stub.get("/v1/tracks") do |env|
        assert_equal "abc,def", env.params["ids"]
        assert_equal "US", env.params["market"]
        spotify_json_response({ "tracks" => [] })
      end
    end

    tool.call(ids: [ "abc", "def" ], market: "US")
  end

  test "declares ids as an array in the input schema" do
    tool = expose_spotify_tool("get_several_tracks") { |_stub| }

    schema = tool.class.input_schema_to_json.deep_stringify_keys
    assert_equal "array", schema["properties"]["ids"]["type"]
    assert_includes schema["required"], "ids"
  end
end
