# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerTransferPlaybackToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "transfer_playback"
  end

  test "transfers playback to a device with play" do
    tool = expose_spotify_player_tool("transfer_playback") do |stub|
      stub.put("/v1/me/player") do |env|
        body = JSON.parse(env.request_body)
        assert_equal %w[dev123], body["device_ids"]
        assert_equal true, body["play"]
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(device_ids: [ "dev123" ], play: true)
  end

  test "transfers without play key when unspecified" do
    tool = expose_spotify_player_tool("transfer_playback") do |stub|
      stub.put("/v1/me/player") do |env|
        body = JSON.parse(env.request_body)
        assert_equal %w[dev123], body["device_ids"]
        refute body.key?("play")
        [ 204, {}, "" ]
      end
    end

    assert_equal "", tool.call(device_ids: [ "dev123" ])
  end
end
