# frozen_string_literal: true

require "test_helper"

class SpotifyGetNewReleasesToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_new_releases"
  end

  test "fetches new releases with query params" do
    tool = expose_spotify_tool("get_new_releases") do |stub|
      stub.get("/v1/browse/new-releases") do |env|
        assert_equal "10", env.params["limit"]
        assert_equal "20", env.params["offset"]
        spotify_json_response({ "albums" => { "items" => [] } })
      end
    end

    result = tool.call(limit: 10, offset: 20)
    assert_equal [], result["albums"]["items"]
  end
end
