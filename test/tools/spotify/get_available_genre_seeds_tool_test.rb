# frozen_string_literal: true

require "test_helper"

class SpotifyGetAvailableGenreSeedsToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_available_genre_seeds"
  end

  test "fetches available genre seeds" do
    tool = expose_spotify_tool("get_available_genre_seeds") do |stub|
      stub.get("/v1/recommendations/available-genre-seeds") do |_env|
        spotify_json_response({ "genres" => %w[acoustic alternative] })
      end
    end

    result = tool.call
    assert_equal %w[acoustic alternative], result["genres"]
  end
end
