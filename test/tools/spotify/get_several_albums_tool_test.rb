# frozen_string_literal: true

require "test_helper"

class SpotifyGetSeveralAlbumsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_several_albums"
  end

  test "fetches several albums with comma-joined ids" do
    tool = expose_spotify_tool("get_several_albums") do |stub|
      stub.get("/v1/albums") do |env|
        assert_equal "abc,def", env.params["ids"]
        assert_nil env.params["market"]
        spotify_json_response({ "albums" => [ { "id" => "abc" }, { "id" => "def" } ] })
      end
    end

    result = tool.call(ids: [ "abc", "def" ])
    assert_equal [ "abc", "def" ], result["albums"].map { |a| a["id"] }
  end

  test "passes market as a query param" do
    tool = expose_spotify_tool("get_several_albums") do |stub|
      stub.get("/v1/albums") do |env|
        assert_equal "abc,def", env.params["ids"]
        assert_equal "US", env.params["market"]
        spotify_json_response({ "albums" => [] })
      end
    end

    tool.call(ids: [ "abc", "def" ], market: "US")
  end

  test "declares ids as an array in the input schema" do
    tool = expose_spotify_tool("get_several_albums") { |_stub| }

    schema = tool.class.input_schema_to_json.deep_stringify_keys
    assert_equal "array", schema["properties"]["ids"]["type"]
    assert_includes schema["required"], "ids"
  end
end
