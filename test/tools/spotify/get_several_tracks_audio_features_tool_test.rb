# frozen_string_literal: true

require "test_helper"

class SpotifyGetSeveralTracksAudioFeaturesToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_several_tracks_audio_features"
  end

  test "fetches audio features with comma-joined ids" do
    tool = expose_spotify_tool("get_several_tracks_audio_features") do |stub|
      stub.get("/v1/audio-features") do |env|
        assert_equal "abc,def", env.params["ids"]
        spotify_json_response({ "audio_features" => [ { "id" => "abc" }, { "id" => "def" } ] })
      end
    end

    result = tool.call(ids: %w[abc def])
    assert_equal %w[abc def], result["audio_features"].map { |f| f["id"] }
  end

  test "declares ids as a required array in the input schema" do
    tool = expose_spotify_tool("get_several_tracks_audio_features") { |_stub| }

    schema = tool.class.input_schema_to_json.deep_stringify_keys
    assert_equal "array", schema["properties"]["ids"]["type"]
    assert_includes schema["required"], "ids"
  end
end
