# frozen_string_literal: true

require "test_helper"

class SpotifyGetAlbumToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_album"
  end

  test "fetches an album by id" do
    tool = expose_spotify_tool("get_album") do |stub|
      stub.get("/v1/albums/xyz789") do |env|
        assert_nil env.params["market"]
        spotify_json_response({ "id" => "xyz789", "name" => "Abbey Road" })
      end
    end

    result = tool.call(id: "xyz789")
    assert_equal "Abbey Road", result["name"]
  end

  test "passes market as a query param" do
    tool = expose_spotify_tool("get_album") do |stub|
      stub.get("/v1/albums/xyz789") do |env|
        assert_equal "GB", env.params["market"]
        spotify_json_response({ "id" => "xyz789" })
      end
    end

    tool.call(id: "xyz789", market: "GB")
  end
end
