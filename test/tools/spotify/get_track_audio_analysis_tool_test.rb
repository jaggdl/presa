# frozen_string_literal: true

require "test_helper"

class SpotifyGetTrackAudioAnalysisToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_track_audio_analysis"
  end

  test "fetches audio analysis for a single track id" do
    tool = expose_spotify_tool("get_track_audio_analysis") do |stub|
      stub.get("/v1/audio-analysis/abc123") do |_env|
        spotify_json_response({ "meta" => { "analyzer_version" => "4.0.0" }, "track" => { "tempo" => 120 } })
      end
    end

    result = tool.call(id: "abc123")
    assert_equal "4.0.0", result.dig("meta", "analyzer_version")
    assert_equal 120, result.dig("track", "tempo")
  end
end
