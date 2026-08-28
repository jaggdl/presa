# frozen_string_literal: true

require "test_helper"

class SpotifyGetRecommendationsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_recommendations"
  end

  test "requests recommendations with seeds and target attributes" do
    tool = expose_spotify_tool("get_recommendations") do |stub|
      stub.get("/v1/recommendations") do |env|
        assert_equal "4NHQUGzhtTLFvgF5SZesLK", env.params["seed_artists"]
        assert_equal "classical,country", env.params["seed_genres"]
        assert_equal "10", env.params["limit"]
        assert_equal "0.8", env.params["target_danceability"]
        assert_equal "0.6", env.params["target_energy"]
        assert_nil env.params["target_tempo"]
        spotify_json_response({ "tracks" => [] })
      end
    end

    tool.call(seed_artists: [ "4NHQUGzhtTLFvgF5SZesLK" ], seed_genres: %w[classical country],
              limit: 10, target_danceability: 0.8, target_energy: 0.6)
  end

  test "declares limit bounds in the input schema" do
    tool = expose_spotify_tool("get_recommendations") { |_stub| }

    schema = tool.class.input_schema_to_json.deep_stringify_keys
    assert_equal 1, schema.dig("properties", "limit", "minimum")
    assert_equal 100, schema.dig("properties", "limit", "maximum")
  end
end
