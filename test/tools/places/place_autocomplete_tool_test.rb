# frozen_string_literal: true

require "test_helper"

class PlacesPlaceAutocompleteToolTest < ActiveSupport::TestCase
  include PlacesToolTestHelper

  test "is exposed for places services" do
    kinds = ApplicationTool.expose_for(services(:places)).map(&:kind)
    assert_includes kinds, "place_autocomplete"
  end

  test "posts a minimal autocomplete request with the api key and default field mask" do
    tool = expose_places_tool("place_autocomplete") do |stub|
      stub.post("/v1/places:autocomplete") do |env|
        assert_equal "test-key", env.request_headers["X-Goog-Api-Key"]
        assert_equal Places::PlaceAutocompleteTool::DEFAULT_FIELDS, env.request_headers["X-Goog-FieldMask"]

        body = JSON.parse(env.request_body)
        assert_equal({ "input" => "Amoeba" }, body)

        places_json_response({ "suggestions" => [ { "placePrediction" => { "placeId" => "ChIJ5YQQf1GHhYARPKG7WLIaOko", "text" => { "text" => "Amoeba Music" } } } ] })
      end
    end

    result = tool.call(input: "Amoeba")
    assert_equal "ChIJ5YQQf1GHhYARPKG7WLIaOko", result["suggestions"].first.dig("placePrediction", "placeId")
  end

  test "passes optional refinements and a session token" do
    tool = expose_places_tool("place_autocomplete") do |stub|
      stub.post("/v1/places:autocomplete") do |env|
        body = JSON.parse(env.request_body)
        assert_equal %w[restaurant], body["includedPrimaryTypes"]
        assert_equal %w[us], body["includedRegionCodes"]
        assert_equal true, body["includeQueryPredictions"]
        assert_equal 5, body["inputOffset"]
        assert_equal 37.7749, body.dig("origin", "latitude")
        assert_equal 5000.0, body.dig("locationBias", "circle", "radius")
        assert_equal "en", body["languageCode"]
        assert_equal "us", body["regionCode"]
        assert_equal "tok-123", body["sessionToken"]
        places_json_response({ "suggestions" => [] })
      end
    end

    tool.call(input: "piz", included_primary_types: [ "restaurant" ], included_region_codes: [ "us" ],
              include_query_predictions: true, input_offset: 5, origin_latitude: 37.7749, origin_longitude: -122.4194,
              bias_latitude: 37.7749, bias_longitude: -122.4194, bias_radius: 5000,
              language_code: "en", region_code: "us", session_token: "tok-123")
  end

  test "builds a locationRestriction circle when restriction coords are given" do
    tool = expose_places_tool("place_autocomplete") do |stub|
      stub.post("/v1/places:autocomplete") do |env|
        body = JSON.parse(env.request_body)
        assert_equal 40.75, body.dig("locationRestriction", "circle", "center", "latitude")
        assert_equal 2000.0, body.dig("locationRestriction", "circle", "radius")
        assert_nil body["locationBias"]
        places_json_response({ "suggestions" => [] })
      end
    end

    tool.call(input: "museum", restrict_latitude: 40.75, restrict_longitude: -73.98, restrict_radius: 2000)
  end

  test "honors a custom field mask" do
    tool = expose_places_tool("place_autocomplete") do |stub|
      stub.post("/v1/places:autocomplete") do |env|
        assert_equal "suggestions.placePrediction.text.text", env.request_headers["X-Goog-FieldMask"]
        places_json_response({ "suggestions" => [] })
      end
    end

    tool.call(input: "pizza", fields: "suggestions.placePrediction.text.text")
  end
end
