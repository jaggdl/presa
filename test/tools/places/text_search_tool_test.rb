# frozen_string_literal: true

require "test_helper"

class PlacesTextSearchToolTest < ActiveSupport::TestCase
  include PlacesToolTestHelper

  test "is exposed for places services" do
    kinds = ApplicationTool.expose_for(services(:places)).map(&:kind)
    assert_includes kinds, "text_search"
  end

  test "posts a text query with the api key and a default field mask" do
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") do |env|
        assert_equal "test-key", env.request_headers["X-Goog-Api-Key"]
        assert_equal Places::TextSearchTool::DEFAULT_FIELDS, env.request_headers["X-Goog-FieldMask"]
        assert_equal "pizza in New York", JSON.parse(env.request_body)["textQuery"]
        places_json_response({ "places" => [ { "id" => "ChIJ", "displayName" => { "text" => "Di Fara" } } ] })
      end
    end

    result = tool.call(text_query: "pizza in New York")
    assert_equal "ChIJ", result["places"].first["id"]
  end

  test "passes optional refinements as camelCase body keys" do
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") do |env|
        body = JSON.parse(env.request_body)
        assert_equal 5, body["pageSize"]
        assert_equal "restaurant", body["includedType"]
        assert_equal true, body["openNow"]
        assert_equal 4.5, body["minRating"]
        assert_equal "DISTANCE", body["rankPreference"]
        assert_equal "US", body["regionCode"]
        assert_equal "en", body["languageCode"]
        assert_equal false, body["strictTypeFiltering"]
        assert_equal "abc123", body["pageToken"]
        places_json_response({ "places" => [] })
      end
    end

    tool.call(text_query: "tacos", page_size: 5, page_token: "abc123", included_type: "restaurant",
              language_code: "en", region_code: "US", open_now: true, min_rating: 4.5,
              rank_preference: "DISTANCE", strict_type_filtering: false)
  end

  test "honors a custom field mask" do
    tool = expose_places_tool("text_search") do |stub|
      stub.post("/v1/places:searchText") do |env|
        assert_equal "places.id,places.displayName", env.request_headers["X-Goog-FieldMask"]
        places_json_response({ "places" => [] })
      end
    end

    tool.call(text_query: "cafe", fields: "places.id,places.displayName")
  end
end
