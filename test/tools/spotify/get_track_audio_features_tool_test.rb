# frozen_string_literal: true

require "test_helper"

class SpotifyGetTrackAudioFeaturesToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_track_audio_features"
  end

  test "fetches audio features for a single track id" do
    tool = expose_spotify_tool("get_track_audio_features") do |stub|
      stub.get("/v1/audio-features/abc123") do |_env|
        spotify_json_response({ "danceability" => 0.8, "energy" => 0.6, "id" => "abc123" })
      end
    end

    result = tool.call(id: "abc123")
    assert_equal "abc123", result["id"]
    assert_equal 0.8, result["danceability"]
  end
end
