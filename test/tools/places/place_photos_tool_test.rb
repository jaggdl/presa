# frozen_string_literal: true

require "test_helper"

class PlacesPlacePhotosToolTest < ActiveSupport::TestCase
  include PlacesToolTestHelper

  test "is exposed for places services" do
    kinds = ApplicationTool.expose_for(services(:places)).map(&:kind)
    assert_includes kinds, "place_photos"
  end

  test "gets photo metadata with the photo name and dimensions" do
    photo = "places/ChIJabcdef/photos/AwU1fK9"
    tool = expose_places_tool("place_photos") do |stub|
      stub.get("/v1/places/ChIJabcdef/photos/AwU1fK9/media") do |env|
        assert_equal "test-key", env.params["key"]
        assert_equal "true", env.params["skipHttpRedirect"]
        assert_equal "400", env.params["maxWidthPx"]
        assert_equal "400", env.params["maxHeightPx"]
        places_json_response({ "name" => "#{photo}/media", "photoUri" => "https://lh3.googleusercontent.com/abc" })
      end
    end

    result = tool.call(photo_name: photo, max_width_px: 400, max_height_px: 400)
    assert_equal "https://lh3.googleusercontent.com/abc", result["photoUri"]
  end

  test "works with only a max height" do
    tool = expose_places_tool("place_photos") do |stub|
      stub.get("/v1/places/ChIJx/photos/Aw/media") do |env|
        assert_equal "800", env.params["maxHeightPx"]
        assert_nil env.params["maxWidthPx"]
        places_json_response({ "photoUri" => "https://lh3.googleusercontent.com/abc" })
      end
    end

    result = tool.call(photo_name: "places/ChIJx/photos/Aw", max_height_px: 800)
    assert_equal "https://lh3.googleusercontent.com/abc", result["photoUri"]
  end
end
