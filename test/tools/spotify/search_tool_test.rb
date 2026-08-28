# frozen_string_literal: true

require "test_helper"

class SpotifySearchToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "search"
  end

  test "searches with comma-joined types and query params" do
    tool = expose_spotify_tool("search") do |stub|
      stub.get("/v1/search") do |env|
        assert_equal "abo", env.params["q"]
        assert_equal "album,track", env.params["type"]
        assert_equal "US", env.params["market"]
        assert_equal "10", env.params["limit"]
        spotify_json_response({ "albums" => { "items" => [] }, "tracks" => { "items" => [] } })
      end
    end

    tool.call(q: "abo", type: %w[album track], market: "US", limit: 10)
  end

  test "declares type as a required array with the allowed enum values" do
    tool = expose_spotify_tool("search") { |_stub| }

    schema = tool.class.input_schema_to_json.deep_stringify_keys
    properties = schema["properties"]

    assert_equal "array", properties["type"]["type"]
    assert_equal %w[album artist playlist track show episode audiobook], properties["type"]["items"]["enum"]
    assert_includes schema["required"], "type"
  end
end
