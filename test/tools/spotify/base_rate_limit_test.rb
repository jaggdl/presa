# frozen_string_literal: true

require "test_helper"

class SpotifyBaseRateLimitTest < ActiveSupport::TestCase
  include SpotifyToolTestHelper

  test "retries a 429 and returns the successful response" do
    calls = 0
    tool = expose_spotify_tool("get_current_user_profile") do |stub|
      stub.get("/v1/me") do
        calls += 1
        if calls == 1
          spotify_json_response({ "error" => { "status" => 429, "message" => "rate limited" } },
                                status: 429, headers: { "retry-after" => "5" })
        else
          spotify_json_response({ display_name: "Ada" })
        end
      end
    end
    client_for(tool).define_singleton_method(:sleep) { |*| }

    result = tool.call
    assert_equal "Ada", result["display_name"]
    assert_equal 2, calls
  end

  test "backs off exponentially when no Retry-After is present" do
    tool = expose_spotify_tool("get_current_user_profile") do |stub|
      stub.get("/v1/me") { spotify_json_response({}, status: 429) }
    end

    slept = []
    client_for(tool).define_singleton_method(:sleep) { |secs| slept << secs }

    tool.call

    assert_equal 3, slept.length
    assert_equal [ 1, 2, 4 ], slept
  end

  test "honors a Retry-After header over exponential backoff" do
    tool = expose_spotify_tool("get_current_user_profile") do |stub|
      stub.get("/v1/me") { spotify_json_response({}, status: 429, headers: { "retry-after" => "2" }) }
    end

    slept = []
    client_for(tool).define_singleton_method(:sleep) { |secs| slept << secs }

    tool.call

    assert_equal [ 2, 2, 2 ], slept
  end

  test "does not retry non-429 errors" do
    calls = 0
    tool = expose_spotify_tool("get_current_user_profile") do |stub|
      stub.get("/v1/me") do
        calls += 1
        spotify_json_response({ "error" => { "status" => 403, "message" => "forbidden" } }, status: 403)
      end
    end
    client_for(tool).define_singleton_method(:sleep) { |*| flunk "should not sleep on non-429" }

    result = tool.call
    assert_equal 1, calls
    assert_equal 403, result.dig("error", "status")
  end
end
