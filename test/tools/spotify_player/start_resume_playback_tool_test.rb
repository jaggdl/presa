# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerStartResumePlaybackToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "start_resume_playback"
  end

  test "resumes playback with no body" do
    tool = expose_spotify_player_tool("start_resume_playback") do |stub|
      stub.put("/v1/me/player/play") do |env|
        assert_nil env.params["device_id"]
        assert_equal "", env.request_body
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call
  end

  test "starts a context with uri and position" do
    tool = expose_spotify_player_tool("start_resume_playback") do |stub|
      stub.put("/v1/me/player/play") do |env|
        assert_equal "dev123", env.params["device_id"]
        body = JSON.parse(env.request_body)
        assert_equal "spotify:album:abc", body["context_uri"]
        assert_equal({ "position" => 5 }, body["offset"])
        [ 204, {}, "" ]
      end
    end

    tool.call(device_id: "dev123", context_uri: "spotify:album:abc", position: 5)
  end

  test "starts by uris with position offset by uri" do
    tool = expose_spotify_player_tool("start_resume_playback") do |stub|
      stub.put("/v1/me/player/play") do |env|
        body = JSON.parse(env.request_body)
        assert_equal %w[spotify:track:a spotify:track:b], body["uris"]
        assert_equal({ "uri" => "spotify:track:a" }, body["offset"])
        assert_equal 30000, body["position_ms"]
        [ 204, {}, "" ]
      end
    end

    tool.call(uris: %w[spotify:track:a spotify:track:b], uri: "spotify:track:a", position_ms: 30_000)
  end
end
