# frozen_string_literal: true

require "test_helper"

class SpotifyGetMyTopItemsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_my_top_items"
  end

  test "requests top tracks with type in the path and query params" do
    tool = expose_spotify_tool("get_my_top_items") do |stub|
      stub.get("/v1/me/top/tracks") do |env|
        assert_equal "long_term", env.params["time_range"]
        assert_equal "10", env.params["limit"]
        assert_equal "20", env.params["offset"]
        spotify_json_response({ "items" => [] })
      end
    end

    tool.call(type: "tracks", time_range: "long_term", limit: 10, offset: 20)
  end

  test "builds the path from the entity type" do
    tool = expose_spotify_tool("get_my_top_items") do |stub|
      stub.get("/v1/me/top/artists") do |_env|
        @artists_hit = true
        spotify_json_response({ "items" => [] })
      end
    end

    tool.call(type: "artists")
    assert @artists_hit, "expected /me/top/artists to be requested"
  end

  test "declares type and time_range enums in the input schema" do
    tool = expose_spotify_tool("get_my_top_items") { |_stub| }

    schema = tool.class.input_schema_to_json.deep_stringify_keys
    properties = schema["properties"]

    assert_equal %w[artists tracks], properties["type"]["enum"]
    assert_equal %w[short_term medium_term long_term], properties["time_range"]["enum"]
    assert_includes schema["required"], "type"
  end
end
