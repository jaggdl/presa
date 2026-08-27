# frozen_string_literal: true

require "test_helper"

class SpotifyGetCurrentUserProfileToolTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "is exposed for spotify services" do
    kinds = ApplicationTool.expose_for(services(:spotify)).map(&:kind)
    assert_includes kinds, "get_current_user_profile"
  end

  test "fetches the current user profile with an auth header" do
    tool = expose_spotify_tool("get_current_user_profile") do |stub|
      stub.get("/v1/me") do |env|
        assert_equal "Bearer test-access-token", env.request_headers["Authorization"]
        spotify_json_response({ display_name: "Ada", id: "ada123", country: "US" })
      end
    end

    result = tool.call
    assert_equal "Ada", result["display_name"]
    assert_equal "ada123", result["id"]
  end
end
