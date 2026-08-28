# frozen_string_literal: true

require "test_helper"

class SpotifyPlayerGetAvailableDevicesToolTest < ActiveSupport::TestCase
  include SpotifyPlayerToolTestHelper

  test "is exposed for spotify_player services" do
    kinds = ApplicationTool.expose_for(services(:spotify_player)).map(&:kind)
    assert_includes kinds, "get_available_devices"
  end

  test "fetches available devices" do
    tool = expose_spotify_player_tool("get_available_devices") do |stub|
      stub.get("/v1/me/player/devices") do
        [ 200, { "content-type" => "application/json" }, JSON.generate({ "devices" => [ { "id" => "abc", "name" => "Office" } ] }) ]
      end
    end

    result = tool.call
    assert_equal "abc", result["devices"].first["id"]
  end
end
