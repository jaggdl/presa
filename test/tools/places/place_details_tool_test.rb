# frozen_string_literal: true

require "test_helper"

class PlacesPlaceDetailsToolTest < ActiveSupport::TestCase
  include PlacesToolTestHelper

  test "is exposed for places services" do
    kinds = ApplicationTool.expose_for(services(:places)).map(&:kind)
    assert_includes kinds, "place_details"
  end

  test "gets a place by id with the api key and default field mask" do
    tool = expose_places_tool("place_details") do |stub|
      stub.get("/v1/places/ChIJ2fzCmcW7j4AR2JzfXBBoh6E") do |env|
        assert_equal "test-key", env.request_headers["X-Goog-Api-Key"]
        assert_equal Places::PlaceDetailsTool::DEFAULT_FIELDS, env.request_headers["X-Goog-FieldMask"]
        places_json_response({ "id" => "ChIJ2fzCmcW7j4AR2JzfXBBoh6E", "displayName" => { "text" => "The Coffee Bar" } })
      end
    end

    result = tool.call(place_id: "ChIJ2fzCmcW7j4AR2JzfXBBoh6E")
    assert_equal "The Coffee Bar", result.dig("displayName", "text")
  end

  test "passes language and region and honors a custom field mask" do
    tool = expose_places_tool("place_details") do |stub|
      stub.get("/v1/places/ChIJ123") do |env|
        assert_equal "en", env.params["languageCode"]
        assert_equal "US", env.params["regionCode"]
        assert_equal "id,websiteUri", env.request_headers["X-Goog-FieldMask"]
        places_json_response({ "id" => "ChIJ123" })
      end
    end

    tool.call(place_id: "ChIJ123", language_code: "en", region_code: "US", fields: "id,websiteUri")
  end
end
