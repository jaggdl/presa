# frozen_string_literal: true

require "test_helper"

class PlacesBaseRateLimitTest < ActiveSupport::TestCase
  include PlacesToolTestHelper

  test "retries a 429 and returns the successful response" do
    calls = 0
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") do
        calls += 1
        if calls == 1
          places_json_response({ "error" => { "status" => 429 } }, status: 429, headers: { "retry-after" => "5" })
        else
          places_json_response({ "places" => [] })
        end
      end
    end
    tool.define_singleton_method(:sleep) { |*| }

    tool.call(text_query: "pizza")
    assert_equal 2, calls
  end

  test "backs off exponentially when no Retry-After is present" do
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") { places_json_response({}, status: 429) }
    end

    slept = []
    tool.define_singleton_method(:sleep) { |secs| slept << secs }

    tool.call(text_query: "pizza")

    assert_equal 3, slept.length
    assert_equal [ 1, 2, 4 ], slept
  end

  test "honors a Retry-After header over exponential backoff" do
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") { places_json_response({}, status: 429, headers: { "retry-after" => "2" }) }
    end

    slept = []
    tool.define_singleton_method(:sleep) { |secs| slept << secs }

    tool.call(text_query: "pizza")

    assert_equal [ 2, 2, 2 ], slept
  end

  test "does not retry non-429 errors" do
    calls = 0
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") do
        calls += 1
        places_json_response({ "error" => { "status" => 403 } }, status: 403)
      end
    end
    tool.define_singleton_method(:sleep) { |*| flunk "should not sleep on non-429" }

    result = tool.call(text_query: "pizza")
    assert_equal 1, calls
    assert_equal 403, result.dig("error", "status")
  end
end
