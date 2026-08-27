# frozen_string_literal: true

require "test_helper"

class PlacesNearbySearchToolTest < ActiveSupport::TestCase
  include PlacesToolTestHelper

  test "is exposed for places services" do
    kinds = ApplicationTool.expose_for(services(:places)).map(&:kind)
    assert_includes kinds, "nearby_search"
  end

  test "posts a circle-based nearby search with the api key and field mask" do
    tool = expose_places_tool("nearby_search") do |stub|
      stub.post("/v1/places:searchNearby") do |env|
        assert_equal "test-key", env.request_headers["X-Goog-Api-Key"]
        assert_equal Places::NearbySearchTool::DEFAULT_FIELDS, env.request_headers["X-Goog-FieldMask"]

        body = JSON.parse(env.request_body)
        assert_equal 37.7937, body.dig("locationRestriction", "circle", "center", "latitude")
        assert_equal(-122.3965, body.dig("locationRestriction", "circle", "center", "longitude"))
        assert_equal 500.0, body.dig("locationRestriction", "circle", "radius")

        places_json_response({ "places" => [ { "id" => "ChIJ", "displayName" => { "text" => "La Mar" } } ] })
      end
    end

    result = tool.call(latitude: 37.7937, longitude: -122.3965, radius: 500)
    assert_equal "La Mar", result["places"].first.dig("displayName", "text")
  end

  test "passes all optional refinements as camelCase body keys" do
    tool = expose_places_tool("nearby_search") do |stub|
      stub.post("/v1/places:searchNearby") do |env|
        body = JSON.parse(env.request_body)
        assert_equal %w[restaurant cafe], body["includedTypes"]
        assert_equal [ "steak_house" ], body["excludedPrimaryTypes"]
        assert_equal 10, body["maxResultCount"]
        assert_equal "DISTANCE", body["rankPreference"]
        assert_equal "en", body["languageCode"]
        assert_equal "US", body["regionCode"]
        places_json_response({ "places" => [] })
      end
    end

    tool.call(latitude: 37.7937, longitude: -122.3965, radius: 1000,
              included_types: [ "restaurant", "cafe" ], excluded_primary_types: [ "steak_house" ],
              max_result_count: 10, rank_preference: "DISTANCE", language_code: "en", region_code: "US")
  end

  test "honors a custom field mask" do
    tool = expose_places_tool("nearby_search") do |stub|
      stub.post("/v1/places:searchNearby") do |env|
        assert_equal "places.id,places.displayName", env.request_headers["X-Goog-FieldMask"]
        places_json_response({ "places" => [] })
      end
    end

    tool.call(latitude: 1, longitude: 2, radius: 100, fields: "places.id,places.displayName")
  end
end
